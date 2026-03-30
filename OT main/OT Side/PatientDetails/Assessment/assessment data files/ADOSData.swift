import Foundation

// MARK: - Model
struct ADOSQuestion {
    let id: Int
    let question: String
    let options: [String]
}

// MARK: - ADOS Question Set
struct ADOSData {

    static let questions: [ADOSQuestion] = [
        ADOSQuestion(id: 1, question: "I prefer to do things on my own, rather than with others.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 2, question: "I prefer doing things the same way – for instance my morning routine or trip to the supermarket.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 3, question: "I find myself strongly absorbed in something – even obsessional.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 4, question: "I am very sensitive to noise and will wear earplugs or cover my ears in certain situations.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 5, question: "Sometimes people say I am rude, even though I think I am being polite.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 6, question: "I find it hard to make new friends.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 7, question: "I can tell if someone is getting bored or annoyed when I am talking to them.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 8, question: "I find it easy to imagine what characters in a book might be thinking or feeling.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 9, question: "I am fascinated by dates, numbers, or strings of information.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 10, question: "In a social group, I can easily keep track of several different people's conversations.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 11, question: "I find social situations easy.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 12, question: "I tend to notice details that others do not.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 13, question: "I would rather go to a library than a party.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 14, question: "I find making up stories easy.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 15, question: "I find myself drawn more to things than people.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 16, question: "I tend to have very strong interests which I get upset about if I can’t pursue.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 17, question: "I enjoy social chit-chat.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 18, question: "When I talk, it isn’t always easy for others to get a word in edgeways.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 19, question: "I am fascinated by numbers.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"]),
        ADOSQuestion(id: 20, question: "I find it difficult to work out people’s intentions.", options: ["Definitely Agree", "Slightly Agree", "Slightly Disagree", "Definitely Disagree"])
    ]
}
