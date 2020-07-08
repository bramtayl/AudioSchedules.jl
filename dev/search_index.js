var documenterSearchIndex = {"docs":
[{"location":"#Interface","page":"Interface","title":"Interface","text":"","category":"section"},{"location":"","page":"Interface","title":"Interface","text":"warning: Performance note\nPresumably due to the limits of inference, scheduling 16 or more synthesizers simultaneously will lead you off a performance cliff. Hopefully this limitation will go away in future versions of Julia.","category":"page"},{"location":"","page":"Interface","title":"Interface","text":"Modules = [AudioSchedules]","category":"page"},{"location":"","page":"Interface","title":"Interface","text":"Modules = [AudioSchedules]","category":"page"},{"location":"#AudioSchedules.AudioSchedule-Tuple{Any,Any}","page":"Interface","title":"AudioSchedules.AudioSchedule","text":"AudioSchedule(triples, the_sample_rate)\n\nReturn a SampledSource. triples should be a vector of triples in the form\n\n(synthesizer, start_time, duration_or_envelope)\n\nwhere synthesizer is anything that supports make_iterator, start_time has units of time (like s), and duration_or_envelope is either a duration (with units of time, like s) or an envelope.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: s, Hz\n\n\njulia> an_envelope = envelope(0, Line => 1s, 1, Line => 1s, 0);\n\n\njulia> triple = (Map(sin, Cycles(440Hz)), 0s, an_envelope);\n\n\njulia> a_schedule = AudioSchedule([triple], 44100Hz);\n\nYou can find the number of samples in an AudioSchedule with length.\n\njulia> the_length = length(a_schedule)\n88200\n\nYou can use the schedule as a source for samples.\n\njulia> read(a_schedule, the_length);\n\nThe schedule must have at least one triple.\n\njulia> AudioSchedule([], 44100Hz)\nERROR: AudioSchedules require at least one triple\n[...]\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.Cycles","page":"Interface","title":"AudioSchedules.Cycles","text":"Cycles(frequency)\n\nCycles from 0 to 2π to repeat at a frequency (with frequency units, like Hz). Supports make_iterator and segments.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: Hz\n\n\njulia> first(make_iterator(Cycles(440Hz), 44100Hz))\n0.0\n\n\n\n\n\n","category":"type"},{"location":"#AudioSchedules.Grow","page":"Interface","title":"AudioSchedules.Grow","text":"Grow(start, rate)\n\nExponentially grow or decay from start (unitless), at a continuous rate (with units per time like 1/s). Supports make_iterator and segments..\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: Hz, s\n\n\njulia> first(make_iterator(Grow(1, 1 / s), 44100Hz))\n1.0\n\n\n\n\n\n","category":"type"},{"location":"#AudioSchedules.Hook","page":"Interface","title":"AudioSchedules.Hook","text":"Hook(rate, slope)\n\nMake a hook shape, with an exponential curve growing at a continuous rate (with units per time like 1/s), followed by a line with slope (with units per time like  1/s). Use with envelope. Supports segments.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: s, Hz\n\n\njulia> envelope(1, Hook(1 / s, 1 / s) => 2s, ℯ + 1)\n((Grow(1.0, 1.0 s^-1), 1.0 s), (Line(2.718281828459045, 1.0 s^-1), 1.0 s))\n\n\n\n\n\n","category":"type"},{"location":"#AudioSchedules.Line","page":"Interface","title":"AudioSchedules.Line","text":"Line(start, slope)\n\nA line from start (unitless) with slope (with units per time like 1/s). Supports make_iterator and segments.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: Hz, s\n\n\njulia> first(make_iterator(Line(0, 1 / s), 44100Hz))\n0.0\n\n\n\n\n\n","category":"type"},{"location":"#AudioSchedules.Map","page":"Interface","title":"AudioSchedules.Map","text":"Map(a_function, synthesizers...)\n\nMap a_function over synthesizers. Supports make_iterator.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: Hz\n\n\njulia> first(make_iterator(Map(sin, Cycles(440Hz)), 44100Hz))\n0.0\n\n\n\n\n\n","category":"type"},{"location":"#AudioSchedules.compound_wave-Tuple{Any}","page":"Interface","title":"AudioSchedules.compound_wave","text":"compound_wave(overtones)\n\nBuild a saw-tooth wave from its partials, starting with the fundamental (1), up to overtones. You can pass overtones as a integer, or as a Val to maximize performance.\n\nTo increase richness but also buziness, increase overtones.\n\njulia> using AudioSchedules\n\n\njulia> compound_wave(3)(π / 4)\n1.4428090415820634\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.envelope-Tuple{Any,Any,Any,Vararg{Any,N} where N}","page":"Interface","title":"AudioSchedules.envelope","text":"envelope(start_level, shape => duration, end_level, more_segments...)\n\nFor all envelope segments, call\n\nsegments(start_level, shape, duration, end_level)\n\nduration should have units of time (like s). For example,\n\nenvelope(0, Line => 1s, 1, Line => 1s, 0)\n\nwill add two segments:\n\nsegments(0, Line, 1s, 1)\nsegments(1, Line, 1s, 0)\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: s\n\n\njulia> envelope(0, Line => 1s, 1, Line => 1s, 0)\n((Line(0.0, 1.0 s^-1), 1 s), (Line(1.0, -1.0 s^-1), 1 s))\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.equal_loudness-Tuple{Map{#s41,Tuple{Cycles}} where #s41}","page":"Interface","title":"AudioSchedules.equal_loudness","text":"equal_loudness(synthesizer::Map{<:Any, Tuple{Cycles}})\n\nChange the volume of a synthesizer so that sounds played at different frequencies will have the same perceived volume. Assumes that the map function has a period of 2π.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: Hz\n\n\njulia> soft = equal_loudness(Map(cos, Cycles(10000Hz)));\n\n\njulia> first(make_iterator(soft, 44100Hz)) ≈ 0.0053035474\ntrue\n\nTechnical details: uses the ISO 226:2003 curve for 40 phons. Scales output by a ratio of the equivalent sound pressure at the current frequency to the equivalent sound pressure at 20Hz (about as low as humans can hear).\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.get_duration-Tuple{SampledSignals.SampleBuf}","page":"Interface","title":"AudioSchedules.get_duration","text":"get_duration(synthesizer)\n\nGet the duration of a synthesizer (with units of time, like s), for synthesizers with an inherent length.\n\njulia> using AudioSchedules\n\n\njulia> using FileIO: load\n\n\njulia> import LibSndFile\n\n\njulia> cd(joinpath(pkgdir(AudioSchedules), \"test\"))\n\n\njulia> get_duration(load(\"clunk.wav\"))\n0.3518820861678005 s\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.make_iterator-Tuple{SampledSignals.SampleBuf,Any}","page":"Interface","title":"AudioSchedules.make_iterator","text":"make_iterator(synthesizer, the_sample_rate)\n\nReturn an iterator that will the play the synthesizer at the_sample_rate (with frequency units, like Hz). The iterator should yield ratios between -1 and 1. Assumes that iterators will never end while they are scheduled.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: Hz\n\n\njulia> using FileIO: load\n\n\njulia> import LibSndFile\n\n\njulia> cd(joinpath(pkgdir(AudioSchedules), \"test\"))\n\n\njulia> first(make_iterator(load(\"clunk.wav\"), 44100Hz))    # TODO: support resampling\n0.00168Q0f15\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.pluck-Tuple{Any}","page":"Interface","title":"AudioSchedules.pluck","text":"pluck(time; decay = -2.5/s, slope = 1/0.005s, peak = 1)\n\nMake an envelope with an exponential decay (with units per time, like 1/s) from the peak, and ramps with ±slope (in units per time, like 1/s) on each side.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: s\n\n\njulia> pluck(1s)\n((Line(0.0, 200.0 s^-1), 0.005 s), (Grow(1.0, -2.5 s^-1), 0.9945839800394016 s), (Line(0.08320399211967063, -200.0 s^-1), 0.0004160199605983683 s))\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.schedule_within-Tuple{Any,Any}","page":"Interface","title":"AudioSchedules.schedule_within","text":"schedule_within(triples, the_sample_rate; maximum_volume = 1.0)\n\nMake an AudioSchedule with triples and the_sample_rate (with frequency units like Hz), then adjust the volume to maximum_volume. Will iterate through triples twice.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: s, Hz\n\n\njulia> triple = (Map(sin, Cycles(440Hz)), 0s, 1s);\n\n\njulia> a_schedule = schedule_within([triple, triple], 44100Hz);\n\n\njulia> extrema(a_schedule) .≈ (-1.0, 1.0)\n(true, true)\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.segments-Tuple{Any,Type{Grow},Any,Any}","page":"Interface","title":"AudioSchedules.segments","text":"segments(start_level, shape, duration, end_level)\n\nCalled by envelope. Return a tuple of pairs in the form (segment, duration), where duration has units of time (like s), with a segment of shape shape. Shapes include Line, Grow, and Hook.\n\njulia> using AudioSchedules\n\n\njulia> using Unitful: s\n\n\njulia> segments(1, Grow, 1s, ℯ)\n((Grow(1.0, 1.0 s^-1), 1 s),)\n\n\n\n\n\n","category":"method"},{"location":"#AudioSchedules.@q_str-Tuple{AbstractString}","page":"Interface","title":"AudioSchedules.@q_str","text":"q\"interval\"\n\nCreate a musical interval. You can specify a numerator (which defaults to 1) and denominator (which defaults to 1) and an octave shift (which defaults to 0).\n\njulia> using AudioSchedules\n\n\njulia> q\"1\"\n1//1\n\njulia> q\"3/2\"\n3//2\n\njulia> q\"2/3o1\"\n4//3\n\njulia> q\"2/3o-1\"\n1//3\n\njulia> q\"o2\"\n4//1\n\njulia> q\"1 + 1\"\nERROR: LoadError: Can't parse interval 1 + 1\n[...]\n\n\n\n\n\n","category":"macro"}]
}
