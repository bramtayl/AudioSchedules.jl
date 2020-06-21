using AudioSchedules: compound_wave, Cycles, envelope, Hook, Line, schedule_within, @q_str, StrictMap
using FileIO: save
import LibSndFile
using Unitful: Hz, s
using Waveforms: sawtoothwave

cd("/home/brandon/Music")

const WAVE = compound_wave(Val(7))

function attack_decay_release(time, ramp = 0.05s)
    envelope(0, Line => ramp, 1, Hook(-2/s, -1/ramp) => time - ramp, 0)
end

function justly(chords, the_sample_rate;
    key = 440Hz,
    seconds_per_beat = 1s
)
    triples = []
    clock = 0.0s
    for notes in chords
        ratio, beats = notes[1]
        key = key * ratio
        for (ratio, beats) in notes[2:end]
            push!(triples, (
                StrictMap(WAVE, Cycles(key * ratio)),
                clock,
                attack_decay_release(beats * seconds_per_beat),
            ))
        end
        clock = clock + beats * seconds_per_beat
    end
    schedule_within(triples, the_sample_rate)
end

SONG = [
    [1 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [3/4 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [q"5/9o1" => 1, q"3/2o1" => 4],
    [1 => 1, q"o1" => 3],
    [1 => 1, 6/5 => 2],
    [1 => 1, q"o1" => 1],
    [6/5 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1"  => 2],
    [1 => 1, 3/2 => 1],
    [2/3 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [3/4 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [3/2 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [2/3 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],

    [q"o2" => -32],
    [1 => 1, q"o1" => 1],
    [1 => 0.5, q"5/4" => 0.5],
    [1 => 0.5, q"4/3" => 0.5],
    [1 => 2, q"3/2" => 2],
    [3/4 => 1, q"5/4o1" => 1],
    [1 => 0.5, q"o1" => 0.5],
    [1 => 0.5, q"9/8o1" => 0.5],
    [1 => 2, q"5/4o1" => 2],
    [q"5/9o1" => 1, q"6/5o1" => 1],
    [1 => 0.5, q"3/2" => 0.5],
    [1 => 0.5, q"8/5" => 0.5],
    [1 => 2, q"9/5" => 2],
    [6/5 => 1, 3/2 => 1],
    [1 => 0.5, 5/4 => 0.5],
    [1 => 0.5, 4/3 => 0.5],
    [1 => 2, 3/2 => 2],
    [4/3 => 1, 5/4 => 1],
    [1 => 0.5, 5/4 => 0.5],
    [1 => 0.5, 45/32 => 0.5],
    [1 => 1, 3/2 => 1],
    [1 => 1, 1 => 1],
    [3/4 => 1, 5/4 => 1],
    [1 => 0.5, 5/4 => 0.5],
    [1 => 0.5, 4/3 => 0.5],
    [1 => 2, 3/2 => 2],
    [3/4 => 1, q"o1" => 1],
    [1 => 0.5, q"o1" => 0.5],
    [1 => 0.5, q"9/8o1" => 0.5],
    [1 => 1, q"5/4o1" => 1],
    [1 => 1, 7/4 => 1],
    [4/3 => 4, 5/4 => 4],

    [q"4/5o-1" => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [3/4 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [4/3 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [3/4 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [q"5/9o1" => 1, q"3/2o1" => 4],
    [1 => 1, q"o1" => 3],
    [1 => 1, 6/5 => 2],
    [1 => 1, q"o1" => 1],
    [q"9/5o-1" => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],
    [q"5/9o1" => 1, q"3/2o1" => 2],
    [1 => 1, q"o1" => 1, 6/5 => 1],
    [4/3 => 1, 1 => 2],
    [1 => 1, 3/2 => 1, q"5/4o1" => 1],
    [2/3 => 1, 1 => 4],
    [1 => 1, 3/2 => 3],
    [1 => 1, q"5/4o1" => 2],
    [1 => 1, 3/2 => 1],

    [q"2/3o2" => -32],
    [1 => 1, q"5/4o1" => 1],
    [1 => 0.5, 3/2 => 0.5],
    [1 => 0.5, 27/16 => 0.5],
    [1 => 2, 15/8 => 2],
    [3/2 => 1, 3/2 => 1],
    [1 => 0.5, 5/4 => 0.5],
    [1 => 0.5, 4/3 => 0.5],
    [1 => 2, 3/2 => 2],
    [2/3 => 1, q"5/4o1" => 1],
    [1 => 0.5, 3/2 => 0.5],
    [1 => 0.5, 27/16 => 0.5],
    [1 => 2, 15/8 => 2],
    [3/2 => 1, 5/4 => 1],
    [1 => 0.5, 1 => 0.5],
    [1 => 0.5, 9/8 => 0.5],
    [1 => 2, 5/4 => 2],
    [q"5/9o1" => 1, 6/5 => 1],
    [1 => 0.5, 6/5 => 0.5],
    [1 => 0.5, 4/3 => 0.5],
    [1 => 1, 3/2 => 1],
    [1 => 1, 1 => 1],
    [q"9/5o-1" => 1, 1 => 1],
    [1 => 0.5, 1 => 1],
    [1 => 0.5, 9/8 => 1],
    [1 => 2, 5/4 => 1],
    [q"5/9o1" => 1, 9/8 => 1],
    [1 => 0.5, 9/8 => 1],
    [1 => 0.5, 6/5 => 1],
    [2/3 => 1, q"o1" => 1],
    [1 => 1, 3/2 => 1],
    [4/3 => 2, 1 => 4]

]

plan = justly(SONG, 44100Hz, key = 161.81Hz, seconds_per_beat = 0.5s)
read(plan, length(plan))