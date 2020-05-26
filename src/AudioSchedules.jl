module AudioSchedules

import Base: eltype, iterate, IteratorEltype, IteratorSize, length, read!, setindex!, show
using Base: Generator, EltypeUnknown, IsInfinite, HasEltype, HasLength, RefValue, tail
using Base.Iterators: repeated, Stateful
using DataStructures: SortedDict
import SampledSignals: samplerate, nchannels, unsafe_read!
using SampledSignals: Hz, s, SampleSource
const TAU = 2 * pi

mutable struct InfiniteStateful{Iterator, Item, State}
    iterator::Iterator
    item_state::Tuple{Item, State}
end
IteratorSize(::Type{<:InfiniteStateful}) = IsInfinite()
IteratorEltype(::Type{InfiniteStateful{<:Any, Item, <:Any}}) where {Item} = Item
InfiniteStateful(iterator) = InfiniteStateful(iterator, iterate(iterator))
function iterate(stateful::InfiniteStateful, state = nothing)
    last_item, state = stateful.item_state
    stateful.item_state = iterate(stateful.iterator, state)
    last_item, nothing
end

mutable struct Plan{InnerIterator} <: SampleSource where {InnerIterator<:Stateful}
    outer_iterator::Vector{Tuple{InnerIterator,Int}}
    outer_state::Int
    inner_iterator::InnerIterator
    item::Float64
    has_left::Int
    the_sample_rate::Int
end

function Plan(
    outer_iterator::Vector{Tuple{InnerIterator,Int}},
    the_sample_rate,
) where {InnerIterator}
    # TODO: save first item
    (inner_iterator, has_left), outer_state = iterate(outer_iterator)
    item, _ = iterate(inner_iterator)
    Plan{InnerIterator}(
        outer_iterator,
        outer_state,
        inner_iterator,
        item,
        has_left,
        the_sample_rate,
    )
end

eltype(source::Plan) = Float64

nchannels(source::Plan) = 1

samplerate(source::Plan) = source.the_sample_rate

function length(source::Plan)
    sum((samples for (_, samples) in source.outer_iterator))
end

# pull out all the type stable parts from the super unstable one below

@noinline function inner_fill!(inner_iterator, item, buf, a_range)
    for index in a_range
        @inbounds buf[index] = item
        item::Float64, inner_state = iterate(inner_iterator)
    end
    item
end

@noinline function switch_iterator!(source, buf, frameoffset, framecount, ::Nothing, until)
    until
end
@noinline function switch_iterator!(
    source,
    buf,
    frameoffset,
    framecount,
    outer_result::Tuple{Tuple{Any,Any},Any},
    until,
)
    (inner_iterator, source.has_left), source.outer_state = outer_result
    source.item, _ = iterate(inner_iterator)
    source.inner_iterator = inner_iterator
    unsafe_read!(source, buf, frameoffset, framecount, until + 1)
end

function unsafe_read!(source::Plan, buf, frameoffset, framecount, from = 1)
    has_left = source.has_left
    inner_iterator = source.inner_iterator
    item = source.item
    empties = framecount - from + 1
    if (has_left >= empties)
        source.has_left = has_left - empties
        source.item = inner_fill!(inner_iterator, item, buf, from:framecount)
        framecount
    else
        until = from + has_left - 1
        inner_fill!(inner_iterator, item, buf, from:until)
        outer_result = iterate(source.outer_iterator, source.outer_state)
        switch_iterator!(source, buf, frameoffset, framecount, outer_result, until)
    end
end

"""
    abstract type Synthesizer

Synthesizers need only support [`make_iterator`](@ref).
"""
abstract type Synthesizer end
export Synthesizer

"""
    make_iterator(synthesizer, the_sample_rate)

Return an iterator that will the play the `synthesizer` at `the_sample_rate`
"""
make_iterator(synthesizer, the_sample_rate) = synthesizer
export make_iterator

struct InfiniteMapIterator{AFunction,Iterators}
    a_function::AFunction
    iterators::Iterators
end

IteratorSize(::Type{<:InfiniteMapIterator}) = IsInfinite

IteratorEltype(::Type{<:InfiniteMapIterator}) = EltypeUnknown

@inline _my_first(something, rest...) = something
@inline my_first(them) = _my_first(them...)

@inline map_unrolled(a_function, them) =
    a_function(my_first(them)), map_unrolled(a_function, tail(them))...
@inline map_unrolled(a_function, ::Tuple{}) = ()
@inline map_unrolled(a_function, tuple_1, tuple_2) =
    a_function(my_first(tuple_1), my_first(tuple_2)), map_unrolled(a_function, tail(tuple_1), tail(tuple_2))...
@inline map_unrolled(a_function, ::Tuple{}, ::Tuple{}) = ()

@inline _my_last(first_one, second_one) = second_one
@inline my_last(pair) = _my_last(pair...)

@inline function iterate(something::InfiniteMapIterator, state...)
    items_states = map_unrolled(iterate, something.iterators, state...)
    something.a_function(map_unrolled(my_first, items_states)...), map_unrolled(my_last, items_states)
end

"""
    InfiniteMap(a_function, synthesizers...)

Map `a_function` over `synthesizers`, assuming that none of the `synthesizers` will end
early.
"""
struct InfiniteMap{AFunction,Synthesizers} <: Synthesizer
    a_function::AFunction
    synthesizers::Synthesizers
    InfiniteMap(a_function::AFunction, synthesizers...) where {AFunction} =
        new{AFunction,typeof(synthesizers)}(a_function, synthesizers)
end
export InfiniteMap

function make_iterator(a_map::InfiniteMap, the_sample_rate)
    InfiniteMapIterator(
        a_map.a_function,
        map(synthesizer -> make_iterator(synthesizer, the_sample_rate), a_map.synthesizers),
    )
end

struct LineIterator
    start::Float64
    plus::Float64
end

IteratorSize(::Type{LineIterator}) = IsInfinite

IteratorEltype(::Type{LineIterator}) = HasEltype

eltype(::Type{LineIterator}) = Float64

@inline function iterate(line::LineIterator, state = line.start)
    state, state + line.plus
end

"""
    Line(start_value, end_value, duration)

A line from `start_value` to `end_value` that lasts for `duration`.
"""
struct Line <: Synthesizer
    start_value::Float64
    end_value::Float64
    duration::Float64
    @inline Line(start_value, end_value, duration) =
        new(start_value, end_value, duration / s)
end
export Line

function make_iterator(line::Line, the_sample_rate)
    start_value = line.start_value
    LineIterator(
        start_value,
        (line.end_value - start_value) / (the_sample_rate * line.duration),
    )
end

struct CyclesIterator
    start::Float64
    plus::Float64
end

IteratorSize(::Type{CyclesIterator}) = IsInfinite

IteratorEltype(::Type{CyclesIterator}) = HasEltype

eltype(::Type{CyclesIterator}) = Float64

@inline function iterate(ring::CyclesIterator, state = ring.start)
    next_state = state + ring.plus
    if next_state >= TAU
        next_state = next_state - TAU
    end
    state, next_state
end

"""
    Cycles(frequency)

Cycles from 0 2π to repeat at a `frequency`.
"""
struct Cycles <: Synthesizer
    frequency::Float64
    Cycles(frequency) = new(frequency / Hz)
end

export Cycles

function make_iterator(cycles::Cycles, the_sample_rate)
    CyclesIterator(0, cycles.frequency / the_sample_rate * TAU)
end

"""
    Envelope(levels, durations, shapes)

Shapes are all functions which return [`Synthesizer`](@ref)s:

```
shape(start_value, end_value, duration) -> Synthesizer
```

`durations` and `levels` list the time and level of the boundaries of segments of the
envelope. For example,

```
Envelope([0.0, 1.0, 1.0, 0.0], [.05 s, 0.9 s, 0.05 s], [Line, Line, Line])
```

will create an envelope with three segments:

```
Line(0.0, 1.0, 0.05 s)
Line(1.0, 1.0, 0.9 s)
Line(1.0, 0.0, 0.05 s)
```

See the example for [`AudioSchedule`](@ref).
"""
struct Envelope{Levels,Durations,Shapes}
    levels::Levels
    durations::Durations
    shapes::Shapes
    function Envelope(
        levels::Levels,
        durations::Durations,
        shapes::Shapes,
    ) where {Levels,Durations,Shapes}
        @assert length(durations) == length(shapes) == length(levels) - 1
        new{Levels,Durations,Shapes}(levels, durations, shapes)
    end
end
export Envelope

const ORCHESTRA = Dict{Symbol,Synthesizer}
const TRIGGERS = SortedDict{Float64,Vector{Tuple{Symbol,Bool}}}

mutable struct AudioSchedule
    orchestra::ORCHESTRA
    triggers::TRIGGERS
end

"""
    AudioSchedule()

Create an `AudioSchedule`.

```jldoctest schedule
julia> using AudioSchedules

julia> using Unitful: s, Hz

julia> a_schedule = AudioSchedule()
AudioSchedule with triggers at () seconds
```

Add a synthesizer to the schedule with [`schedule!`](@ref). You can schedule for a duration
in seconds, or use an [`Envelope`](@ref).

```jldoctest schedule
julia> envelope = Envelope((0, 0.25, 0), (0.05s, 0.95s), (Line, Line));

julia> schedule!(a_schedule, InfiniteMap(sin, Cycles(440Hz)), 0s, envelope)

julia> schedule!(a_schedule, InfiniteMap(sin, Cycles(440Hz)), 1s, envelope)

julia> schedule!(a_schedule, InfiniteMap(sin, Cycles(550Hz)), 1s, envelope)

julia> a_schedule
AudioSchedule with triggers at (0.0, 0.05, 1.0, 1.05, 2.0) seconds
```

Then, you can create a `SampledSource` from the schedule using [`Plan`](@ref).

```jldoctest schedule
julia> using SampledSignals: unsafe_read!

julia> a_plan = Plan(a_schedule, 44100Hz);
```

You can find the number of samples in a `Plan` with length.

```jldoctest schedule
julia> the_length = length(a_plan)
88200
```

You can use `Plan` as a source for samples.

```jldoctest schedule
julia> buf = Vector{Float64}(undef, the_length);

julia> unsafe_read!(a_plan, buf, 0, the_length);

julia> buf[1:4] == [0.0, 7.102984600764591e-6, 2.835612782188846e-5, 6.359232681199096e-5]
true
```
"""
AudioSchedule() = AudioSchedule(ORCHESTRA(), TRIGGERS())
export AudioSchedule

"""
    schedule!(schedule::AudioSchedule, synthesizer::Synthesizer, start_time, duration)

Schedule an audio synthesizer to be added to the `schedule`, starting at `start_time` and
lasting for `duration`. You can also pass an [`Envelope`](@ref) as a duration. See the
example for [`AudioSchedule`](@ref).
"""
function schedule!(
    a_schedule::AudioSchedule,
    synthesizer::Synthesizer,
    start_time,
    duration,
)
    start_time_unitless = start_time / s
    triggers = a_schedule.triggers
    label = gensym("instrument")
    stop_time = start_time_unitless + duration / s
    a_schedule.orchestra[label] = synthesizer
    start_trigger = label, true
    if haskey(triggers, start_time_unitless)
        push!(triggers[start_time_unitless], start_trigger)
    else
        triggers[start_time_unitless] = [start_trigger]
    end
    stop_trigger = label, false
    if haskey(triggers, stop_time)
        push!(triggers[stop_time], stop_trigger)
    else
        triggers[stop_time] = [stop_trigger]
    end
    nothing
end

function schedule!(
    a_schedule::AudioSchedule,
    synthesizer::Synthesizer,
    start_time,
    envelope::Envelope,
)
    durations = envelope.durations
    levels = envelope.levels
    shapes = envelope.shapes
    index = 1
    for index = 1:length(durations)
        duration = durations[index]
        schedule!(
            a_schedule,
            InfiniteMap(
                *,
                synthesizer,
                shapes[index](levels[index], levels[index+1], duration),
            ),
            start_time,
            duration,
        )
        start_time = start_time + duration
    end
end
export schedule!

show(io::IO, a_schedule::AudioSchedule) =
    print(io, "AudioSchedule with triggers at $((keys(a_schedule.triggers)...,)) seconds")

function conduct(::Tuple{})
    repeated(0.0)
end

function conduct(iterators)
    InfiniteMapIterator(+, iterators)
end

"""
    Plan(a_schedule::AudioSchedule)

Return a `SampledSource` for the schedule.
"""
function Plan(a_schedule::AudioSchedule, the_sample_rate)
    the_sample_rate_unitless = the_sample_rate / Hz
    time = Ref(0.0)
    stateful_orchestra = Dict(
        (label, (InfiniteStateful(make_iterator(synthesizer, the_sample_rate_unitless)), false)) for (label, synthesizer) in pairs(a_schedule.orchestra)
    )
    Plan(
        [
            begin
                together = conduct(((
                    iterator for (iterator, is_on) in values(stateful_orchestra) if is_on
                )...,))
                for (label, is_on) in trigger_list
                    iterator, _ = stateful_orchestra[label]
                    stateful_orchestra[label] = iterator, is_on
                end
                samples = round(Int, (end_time - time[]) * the_sample_rate_unitless)
                time[] = end_time
                together, samples
            end for (end_time, trigger_list) in pairs(a_schedule.triggers)
        ],
        the_sample_rate_unitless,
    )
end
export Plan

end
