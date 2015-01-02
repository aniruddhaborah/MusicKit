import Cocoa

extension Array {
    func rotate(n: Int) -> [T] {
        let count = self.count
        let index = n % count
        return Array(self[index..<count] + self[0..<index])
    }
}

enum LetterName : String {
    case C = "C"
    case D = "D"
    case E = "E"
    case F = "F"
    case G = "G"
    case A = "A"
    case B = "B"
}

enum Accidental : String {
    case Natural = "♮"
    case Sharp = "♯"
    case Flat = "♭"
    case DoubleSharp = "𝄪"
    case DoubleFlat = "𝄫"
}

typealias PitchClassName = (LetterName, Accidental)

struct PitchClass {
    let index : UInt
    var names : [PitchClassName] {
        switch self.index {
        case 0:
            return [(.C, .Natural), (.B, .Sharp)]
        case 1:
            return [(.D, .Flat), (.C, .Sharp)]
        case 2:
            return [(.D, .Natural)]
        case 3:
            return [(.E, .Flat), (.D, .Sharp)]
        case 4:
            return [(.E, .Natural)]
        case 5:
            return [(.F, .Natural), (.E, .Sharp)]
        case 6:
            return [(.F, .Sharp), (.G, .Flat)]
        case 7:
            return [(.G, .Natural)]
        case 8:
            return [(.A, .Flat), (.G, .Sharp)]
        case 9:
            return [(.A, .Natural)]
        case 10:
            return [(.B, .Flat), (.A, .Sharp)]
        case 11:
            return [(.B, .Natural), (.C, .Flat)]
        default:
            return []
        }
    }
}

struct Pitch {
    let midiNumber : UInt
    var noteName : String

    init(midiNumber: UInt, noteName: String = "") {
        self.midiNumber = midiNumber
        self.noteName = noteName.utf16Count > 0 ? noteName : Pitch.noteName(self.midiNumber)
    }

    var frequency : Float {
        return 440 // TODO
    }

    var pitchClass : PitchClass {
        return Pitch.pitchClass(self.midiNumber)
    }

    var octaveNumber : Int {
        return Pitch.octaveNumber(self.midiNumber)
    }

    static func pitchClass(midiNumber: UInt) -> PitchClass {
        return PitchClass(index: midiNumber%12)
    }

    static func octaveNumber(midiNumber: UInt) -> Int {
        return (midiNumber - 12)/12
    }

    /// If the optional neighbor letter name parameter is provided, noteName will return
    /// the optimal enharmonic equivalent.
    static func noteName(midiNumber: UInt, neighbor: LetterName? = nil) -> String {
        let pitchClass = PitchClass(index: (midiNumber%12))
        var nameOptional : (LetterName, Accidental)? = pitchClass.names.first
        if let neighborLetter = neighbor {
            for t in pitchClass.names {
                if t.0 != neighborLetter {
                    nameOptional = t
                    break
                }
            }
        }

        if let name = nameOptional {
            let letterName = name.0.rawValue
            let accidental = name.1 == .Natural ? "" : name.1.rawValue
            return "\(letterName)\(accidental)\(Pitch.octaveNumber(midiNumber))"
        }
        else {
            return ""
        }
    }
}

struct Scale {
    let intervals : [Float]

    init!(intervals: [Float]) {
        let sum = intervals.reduce(0, combine: +)
        if sum%12 != 0 {
            return nil
        }
        self.intervals = intervals
    }

    /// Returns the number of semitones from the first note of the scale to the given index
    func semitones(index: Int) -> Float {
        let scaleLength = self.intervals.count
        let octaves = Int(index/scaleLength)
        let indexRemainder = index%scaleLength
        let semitoneRemainder = self.intervals[0..<indexRemainder].reduce(0.0, combine: +)
        return Float(octaves)*12.0 + semitoneRemainder
    }

    static let Chromatic = Scale(intervals: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
    static let Octatonic1 = Scale(intervals: [2, 1, 2, 1, 2, 1, 2, 1])
    static let Octatonic2 = Scale(intervals: Octatonic1!.intervals.rotate(1))
    static let Major = Scale(intervals: [2, 2, 1, 2, 2, 2, 1])
    static let Dorian = Scale(intervals: Major.intervals.rotate(1))
    static let Phrygian = Scale(intervals: Major.intervals.rotate(2))
    static let Lydian = Scale(intervals: Major.intervals.rotate(3))
    static let Mixolydian = Scale(intervals: Major.intervals.rotate(4))
    static let Minor = Scale(intervals: Major.intervals.rotate(5))
    static let Locrian = Scale(intervals: Major.intervals.rotate(6))
}

struct ScaleCollection : CollectionType {
    let firstPitch : Pitch
    let scale : Scale
    let startIndex : Int
    let endIndex : Int

    func generate() -> GeneratorOf<Pitch> {
        var midiNum = firstPitch.midiNumber + Int(scale.semitones(startIndex))
        var scaleLength = scale.intervals.count
        var index = startIndex
        var degree = index%scaleLength
        return GeneratorOf<Pitch> {
            if index < self.endIndex {
                let pitch = Pitch(midiNumber: midiNum)
                midiNum = midiNum + Int(self.scale.intervals[degree])
                degree = (++index)%scaleLength
                return pitch
            }
            else {
                return nil
            }
        }
    }

    subscript(i: Int) -> Pitch {
        let midiNum = firstPitch.midiNumber + Int(scale.semitones(startIndex + i))
        return Pitch(midiNumber: midiNum)
    }
}


var sc = ScaleCollection(firstPitch: Pitch(midiNumber: 23), scale: Scale.Major,
    startIndex: 0, endIndex: 7)
for p in sc {
    print(p.noteName)
    print("\n")
}


print(sc[3].noteName)






