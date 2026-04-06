//
//  AIAssistManager.swift
//  OT main
//
//  Created by Garvit Pareek on 04/04/2026.
//

import Speech
import Foundation
import Combine
import NaturalLanguage
import CoreML

class AIAssistManager: NSObject, SFSpeechRecognizerDelegate {
    static let shared = AIAssistManager()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var isListening = false
    var currentPatientID: String?
    
    // MARK: - CoreML Setup
    // Load the model you built in Create ML
    private lazy var textClassifier: NLModel? = {
        do {
            let config = MLModelConfiguration()
            let mlModel = try ClinicalAssistantModel(configuration: config).model
            return try NLModel(mlModel: mlModel)
        } catch {
            print("Failed to load CoreML model: \(error)")
            return nil
        }
    }()
    
    func startListening(for patientID: String) {
            self.currentPatientID = patientID
            
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        print("🎤 AI Assist: Microphone Authorized! Starting to listen...")
                        self?.beginAudioRecording()
                    case .denied:
                        print("🛑 AI Assist: Permission denied.")
                    case .restricted, .notDetermined:
                        print("🛑 AI Assist: Speech recognition restricted/not determined.")
                    @unknown default:
                        break
                    }
                }
            }
        }
    func stopListening() {
        debounceTimer?.invalidate()
        debounceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }
    
    // Debounce timer: waits for a pause in speech before classifying
    private var debounceTimer: Timer?
    // Tracks the last text we sent to CoreML to avoid re-processing the same partial result
    private var lastProcessedText: String = ""
    
    private func beginAudioRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Reset state for new session
        lastProcessedText = ""
        debounceTimer?.invalidate()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                print("👂 AI Heard: \(spokenText)")
                
                if result.isFinal {
                    // Final result: cancel any pending debounce and classify immediately
                    self.debounceTimer?.invalidate()
                    self.debounceTimer = nil
                    if spokenText != self.lastProcessedText {
                        self.lastProcessedText = spokenText
                        self.routeAIInsight(text: spokenText)
                    }
                } else {
                    // Partial result: debounce — only classify after 1.5s of silence
                    // This ensures CoreML gets a complete thought, not individual words
                    self.debounceTimer?.invalidate()
                    self.debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        // Only classify if the text has actually changed since last time
                        guard spokenText != self.lastProcessedText else { return }
                        // Only classify if we have enough words to form a meaningful phrase
                        let wordCount = spokenText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
                        guard wordCount >= 3 else { return }
                        self.lastProcessedText = spokenText
                        self.routeAIInsight(text: spokenText)
                    }
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.debounceTimer?.invalidate()
                self.debounceTimer = nil
                self.stopListening()
                if self.isListening { self.beginAudioRecording() } // Auto-restart seamlessly
            }
        }
    }

    // MARK: - The AI Router
        private func routeAIInsight(text: String) {
        guard let pid = currentPatientID, let classifier = textClassifier else { return }
        
        // Advanced NLP: Split the continuous speech into logical chunks so the AI can handle multiple independent statements
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".?!"))
        var chunks: [String] = []
        for sentence in sentences {
            // Split further by common coordinating conjunctions
            let subChunks = sentence.components(separatedBy: " and ")
            chunks.append(contentsOf: subChunks)
        }
        
        for chunk in chunks {
            let processedChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            guard processedChunk.count > 5 else { continue } // Skip simple filler like "so" or "yes"
            
            // Allow up to 3 strong predictions per chunk (in case of compound features)
            let hypotheses = classifier.predictedLabelHypotheses(for: processedChunk, maximumCount: 3)
            let viableLabels = hypotheses.filter { $0.value > 0.15 }.keys
            
            print("🗣️ Heard Chunk: '\(processedChunk)' ---> 🤖 Predicted: \(Array(viableLabels))")
            
            for label in viableLabels {
                handlePredictedLabel(label, pid: pid)
            }
        }
    }
    private func mapTextToOptionIndex(_ text: String) -> Int? {
        let cleanText = text.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "-", with: "")
        
        let index0 = ["yes", "ontime", "definitelyagree", "ageappropriate", "independently", "independent", "allshapes", "alltypes", "correctposture", "fistedgrip", "tooheavy", "crawledontime", "hypotonia", "normalgait", "integrated", "frequently", "good", "meltdowns", "10+minutes", "yesmost", "yesleft", "yesright"]
        let index1 = ["sometimes", "delayed", "slightlyagree", "emerging", "withassistance", "withhelp", "someshapes", "straightonly", "needscorrection", "digitalpronate", "toolight", "skippedcrawling", "withdifficulty", "hypertonia", "toewalking", "stillpresent", "shutdowns", "limited", "510minutes", "partially", "some", "somewhat", "slowbutaccurate", "below average"]
        let index2 = ["no", "notachieved", "slightlydisagree", "notobserved", "onlycircle", "cannotuse", "cannotdo", "cannotcut", "cannothold", "tripod", "appropriate", "normaltone", "widebase", "both", "verylimited", "under5minutes", "rarely", "inaccurate", "cannotperform", "notestablished", "cannotstack"]
        let index3 = ["definitelydisagree", "unsure", "notageappropriate", "none", "nottried", "notholdingyet", "variable", "mixed", "otherabnormality", "nottested", "never"]
        
        if index0.contains(cleanText) { return 0 }
        if index1.contains(cleanText) { return 1 }
        if index2.contains(cleanText) { return 2 }
        if index3.contains(cleanText) { return 3 }
        return nil
    }

    private func handlePredictedLabel(_ predictedLabel: String, pid: String) {
        let components = predictedLabel.components(separatedBy: "_")
        
        // --- 1. HANDLE DYNAMIC ASSESSMENTS (GM, FM, COG, ADOS, PD) ---
        if components.count >= 3 {
            let prefix = components[0]
            let qNumStr = components[1].replacingOccurrences(of: "Q", with: "")
            
            if let qNum = Int(qNumStr) {
                let optStr = components[2...].joined(separator: "")
                let finalOptIdx = Int(optStr) ?? mapTextToOptionIndex(optStr)
                
                if let optIdx = finalOptIdx {
                    let qIdx = qNum - 1
                
                switch prefix {
                case "GM", "GrossMotor":
                    let key = "GrossMotor_Q\(qNum)"
                    if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                        updateRadioAnswer(pid: pid, assessment: "Gross Motor Skills", questionIndex: qIdx, optionIndex: optIdx)
                    }
                case "FM", "FineMotor":
                    let key = "FineMotor_Q\(qNum)"
                    if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                        updateRadioAnswer(pid: pid, assessment: "Fine Motor Skills", questionIndex: qIdx, optionIndex: optIdx)
                    }
                case "COG", "Cognitive", "CognitiveSkills":
                    let key = "CognitiveSkills_Q\(qNum)"
                    if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                        updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: qIdx, optionIndex: optIdx)
                    }
                case "ADOS":
                    let key = "ADOS_Q\(qNum)"
                    if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                        updateRadioAnswer(pid: pid, assessment: "ADOS", questionIndex: qIdx, optionIndex: optIdx)
                    }
                case "PD", "PatientDifficulties":
                    let key = "PatientDifficulties_Q\(qNum)"
                    if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                        updateRadioAnswer(pid: pid, assessment: "Patient Difficulties", questionIndex: qIdx, optionIndex: optIdx)
                    }
                default:
                    break
                }
                
                
                if ["GM", "GrossMotor", "FM", "FineMotor", "COG", "Cognitive", "CognitiveSkills", "ADOS", "PD", "PatientDifficulties"].contains(prefix) {
                    return
                }
                } // End if let optIdx
            } // End if let qNum
        } // End if components.count >= 3
        
        // --- 2. HANDLE SPECIFIC LABELS (Sensory, Birth, Medical, School, etc.) ---
        switch predictedLabel {
            
        // MARK: Hand Dominance (Gross Motor)
        case let label where label.hasPrefix("GrossMotor_Hand_"):
            var optIdx = 3 // default to Unsure
            if label.contains("Right") { optIdx = 1 }
            else if label.contains("Left") { optIdx = 0 }
            else if label.contains("None") || label.contains("NotEstablished") { optIdx = 2 }
            
            let lockKey = "GrossMotor_Q14" 
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateRadioAnswer(pid: pid, assessment: "Gross Motor Skills", questionIndex: 13, optionIndex: optIdx)
            }
            
        // MARK: Sensory Profile
        case let label where label.hasPrefix("Sensory_") || label.hasPrefix("SP_"):
            typealias SMap = (sIdx: Int, qIdx: Int, oIdx: Int)
            let sensoryMap: [String: SMap] = [
                // TACTILE (0)
                "Sensory_Tactile_ResistsLightTouch":    (0, 0, 0),
                "Sensory_Tactile_AvoidsClothing":       (0, 1, 0),
                "Sensory_Tactile_DislikesTouch":        (0, 2, 0),
                "Sensory_Tactile_SeeksTactile":         (0, 3, 0),
                "Sensory_Tactile_GroomingDifficulty":   (0, 4, 0),
                "Sensory_Tactile_FoodTexture":          (0, 5, 0),
                "Sensory_Tactile_Barefoot":             (0, 6, 0),
                "Sensory_Tactile_PainReaction":         (0, 7, 0),
                // PROPRIOCEPTION (1)
                "Sensory_Proprio_SeeksHeavyWork":       (1, 0, 0),
                "Sensory_Proprio_HugsTooTight":         (1, 1, 0),
                "Sensory_Proprio_Chews":                (1, 2, 0),
                "Sensory_Proprio_PoorForce":            (1, 3, 0),
                "Sensory_Proprio_LeansOnWalls":         (1, 4, 0),
                "Sensory_Proprio_TightClothing":        (1, 5, 0),
                // VESTIBULAR (2)
                "Sensory_Vestibular_SeeksMovement":     (2, 0, 0),
                "Sensory_Vestibular_Dizzy":             (2, 1, 0),
                "Sensory_Vestibular_FearsMovement":     (2, 2, 0),
                "Sensory_Vestibular_PoorBalance":       (2, 3, 0),
                "Sensory_Vestibular_Rocks":             (2, 4, 0),
                "Sensory_Vestibular_AvoidsPlayground":  (2, 5, 0),
                // AUDITORY (3)
                "Sensory_Auditory_CoversEars":          (3, 0, 0),
                "Sensory_Auditory_AvoidsLoud":          (3, 0, 0),
                "Sensory_Auditory_SoundDistress":       (3, 1, 0),
                "Sensory_Auditory_NotHear":             (3, 2, 0),
                "Sensory_Auditory_SeeksLoud":           (3, 3, 0),
                "Sensory_Auditory_Distracted":          (3, 4, 0),
                "Sensory_Auditory_DistractedByNoise":   (3, 4, 0),
                // VISUAL (4)
                "Sensory_Visual_UnusualAngles":         (4, 0, 0),
                "Sensory_Visual_StaresAtLights":        (4, 1, 0),
                "Sensory_Visual_CoversEye":             (4, 2, 0),
                "Sensory_Visual_ClutterDistracted":     (4, 3, 0),
                "Sensory_Visual_LinesUpObjects":        (4, 4, 0),
                "Sensory_Visual_TrackingDifficulty":    (4, 5, 0),
                // OLFACTORY (5)
                "Sensory_Olfactory_SmellsFood":         (5, 0, 0),
                "Sensory_Olfactory_SmellsObjects":      (5, 1, 0),
                "Sensory_Olfactory_SmellReaction":      (5, 2, 0),
                // GUSTATORY (6)
                "Sensory_Gustatory_LimitedFoods":       (6, 0, 0),
                "Sensory_Gustatory_RefoodsTexture":     (6, 1, 0),
                "Sensory_Gustatory_Gags":               (6, 2, 0),
                "Sensory_Gustatory_CravesSpicy":        (6, 3, 0),
                // INTEROCEPTION (7)
                "Sensory_Intero_NotHungry":             (7, 0, 0),
                "Sensory_Intero_NotToilet":             (7, 1, 0),
                "Sensory_Intero_PainAwareness":         (7, 2, 0),
                "Sensory_Intero_NotFatigue":            (7, 3, 0),
                // BEHAVIORAL (8)
                "Sensory_Behav_Stimming":               (8, 0, 0),
                "Sensory_Behav_RigidRoutines":          (8, 1, 0),
                "Sensory_Behav_NarrowInterests":        (8, 2, 0),
                "Sensory_Behav_Aggressive":             (8, 3, 0),
                "Sensory_Behav_SelfInjury":             (8, 4, 0),
                "Sensory_Behav_TransitionDifficulty":   (8, 5, 0),
                "Sensory_Behav_FrustrationTolerance":   (8, 6, 1),
                "Sensory_Behav_Meltdowns":              (8, 7, 0),
                // ATTENTION (9)
                "Sensory_Attention_PreferredActivity":  (9, 0, 0),
                "Sensory_Attention_NonPreferred":       (9, 1, 2),
                "Sensory_Attention_ShiftsAttention":    (9, 2, 2),
                "Sensory_Attention_MultiStep":          (9, 3, 2),
                "Sensory_Attention_Plans":              (9, 4, 2),
                "Sensory_Attention_Initiates":          (9, 5, 2),
                "Sensory_Attention_CantStop":           (9, 6, 0),
            ]
            
            if let mapping = sensoryMap[label] {
                let sectionNames = ["Tactile","Proprioception","Vestibular","Auditory","Visual","Olfactory","Gustatory","Interoception","Behavioral","Attention"]
                let sectionTitle = mapping.sIdx < sectionNames.count ? sectionNames[mapping.sIdx] : "\(mapping.sIdx)"
                let lockKey = "SensoryProfile_\(sectionTitle)_Q\(mapping.qIdx)"
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                    updateSensoryAnswer(pid: pid, sectionIndex: mapping.sIdx, questionIndex: mapping.qIdx, optionIndex: mapping.oIdx)
                }
            } else if components.count == 4, let sIdx = Int(components[1]), let qIdx = Int(components[2]), let oIdx = Int(components[3]) {
                let lockKey = "SensoryProfile_\(sIdx)_Q\(qIdx)"
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                    updateSensoryAnswer(pid: pid, sectionIndex: sIdx, questionIndex: qIdx, optionIndex: oIdx)
                }
            }

        // MARK: Birth History
            // MARK: Birth History (Prenatal, Birth, Neonatal)
        case let label where label.hasPrefix("BH_") || label.hasPrefix("BirthHistory_"):
                        var field = ""; var value = ""
                        
                        switch label {
                        // Prenatal
                        case "BH_Prenatal_Planned_No": field = "Was the pregnancy planned?"; value = "No"
                        case "BH_Prenatal_Planned_Yes": field = "Was the pregnancy planned?"; value = "Yes"
                        case "BH_Prenatal_Infections": field = "Any infections during pregnancy (TORCH)?"; value = "Yes - reported infection"
                        case "BH_Prenatal_Medications": field = "Medications taken during pregnancy"; value = "Yes - medications taken"
                        case "BH_Prenatal_Medications_None": field = "Medications taken during pregnancy"; value = "None reported"
                        case "BH_Prenatal_Diabetes": field = "Gestational diabetes or hypertension"; value = "Gestational Diabetes"
                        case "BH_Prenatal_Hypertension": field = "Gestational diabetes or hypertension"; value = "Hypertension"
                        case "BH_Prenatal_FetalDistress": field = "Any fetal distress noted during scans?"; value = "Yes - distress noted"
                        case "BH_Prenatal_Checkups_Regular": field = "Number of prenatal check-ups"; value = "Regular checkups"
                        case "BH_Prenatal_Checkups_Late": field = "Number of prenatal check-ups"; value = "Late/Irregular checkups"
                        case "BH_Prenatal_Ultrasound_Abnormal": field = "Any abnormalities on ultrasound?"; value = "Yes - abnormalities noted"
                        case "BH_Prenatal_Multiples": field = "Single or multiple pregnancy (twins, triplets)?"; value = "Multiple (Twins/Triplets)"
                        case "BH_Prenatal_Single": field = "Single or multiple pregnancy (twins, triplets)?"; value = "Single"

                        // Birth
                        case "BH_Birth_Type_NVD", "BirthHistory_DeliveryNormal": field = "Type of delivery (NVD / C-section / Assisted)"; value = "Normal Vaginal Delivery (NVD)"
                        case "BH_Birth_Type_CSection_Emergency": field = "If C-section — elective or emergency, reason?"; value = "Emergency"
                        case "BH_Birth_Type_CSection_Elective": field = "If C-section — elective or emergency, reason?"; value = "Elective"
                        case "BH_Birth_Type_Assisted": field = "Type of delivery (NVD / C-section / Assisted)"; value = "Assisted (Forceps/Vacuum)"
                        case "BH_Birth_Gestation_Preterm", "BirthHistory_PreTerm": field = "Gestation at birth (term 37–42 weeks / preterm / post-term)"; value = "Preterm"
                        case "BH_Birth_Gestation_Term", "BirthHistory_Term": field = "Gestation at birth (term 37–42 weeks / preterm / post-term)"; value = "Term (37-42 weeks)"
                        case "BH_Birth_Gestation_PostTerm": field = "Gestation at birth (term 37–42 weeks / preterm / post-term)"; value = "Post-term"
                        case "BH_Birth_Weight_Low": field = "Birth weight (low birth weight < 2.5 kg?)"; value = "Low birth weight (<2.5 kg)"
                        case "BH_Birth_Weight_High": field = "Birth weight (low birth weight < 2.5 kg?)"; value = "High birth weight"
                        case "BH_Birth_APGAR_Good": field = "APGAR score at 1 minute and 5 minutes"; value = "Good/Normal scores"
                        case "BH_Birth_APGAR_Low": field = "APGAR score at 1 minute and 5 minutes"; value = "Low scores reported"
                        case "BH_Birth_Cry_No": field = "Did the baby cry immediately at birth?"; value = "No - delayed or absent cry"
                        case "BH_Birth_Cry_Yes": field = "Did the baby cry immediately at birth?"; value = "Yes - cried immediately"
                        case "BH_Birth_Resuscitation_Yes": field = "Was resuscitation needed?"; value = "Yes - required oxygen/resuscitation"
                        case "BH_Neonatal_Jaundice_Yes", "BirthHistory_Jaundice": field = "Any jaundice (neonatal hyperbilirubinemia)?"; value = "Yes (reported by parent)"
                        case "BH_Birth_NICU_Yes", "BirthHistory_NICU": field = "NICU admission — duration and reason?"; value = "Yes - NICU admission required"
                        case "BH_Birth_Injuries_Yes": field = "Any birth injuries?"; value = "Yes - birth injury reported"
                        case "BH_Birth_Meconium_Yes": field = "Was meconium present in the amniotic fluid?"; value = "Yes - meconium present"
                        case "BH_Birth_Cord_Nuchal": field = "Cord complications (nuchal cord, cord prolapse)?"; value = "Nuchal cord (around neck)"
                        case "BH_Birth_Cord_Prolapse": field = "Cord complications (nuchal cord, cord prolapse)?"; value = "Cord prolapse"

                        // Neonatal Period
                        case "BH_Neonatal_Feed_Good": field = "Was the baby able to feed (breast/bottle) soon after birth?"; value = "Yes - fed well"
                        case "BH_Neonatal_Feed_Poor": field = "Was the baby able to feed (breast/bottle) soon after birth?"; value = "No - feeding difficulties"
                        case "BH_Neonatal_Seizures_Yes": field = "Any seizures in the neonatal period?"; value = "Yes - neonatal seizures reported"
                        case "BH_Neonatal_Temp_Poor": field = "Temperature regulation problems?"; value = "Yes - required warmer/incubator"
                        case "BH_Neonatal_Hypoglycemia_Yes": field = "Hypoglycemia in the newborn?"; value = "Yes - low blood sugar reported"
                        
                        default: return
                        }
                        
                        let lockKey = "BirthHistory_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                        if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                            updateBirthHistoryField(pid: pid, fieldName: field, value: value)
                        }
        // MARK: Medical History
        case let label where label.hasPrefix("Medical_") || label.hasPrefix("MedicalHistory_"):
            var cond = ""
            let l = label.lowercased()
            if l.contains("asd") || l.contains("autism") { cond = "Autism Spectrum Disorder (ASD)" }
            else if l.contains("id") || l.contains("intellectual") { cond = "Intellectual Disability (ID)" }
            else if l.contains("adhd") { cond = "ADHD — Combined, Inattentive, or Hyperactive-Impulsive" }
            else if l.contains("dcd") || l.contains("coordination") && !l.contains("motor") { cond = "Developmental Coordination Disorder (DCD)" }
            else if l.contains("epilepsy") || l.contains("seizure") { cond = "Epilepsy / Seizure Disorder" }
            else if l.contains("anxiety") { cond = "Anxiety Disorders" }
            else if l.contains("spd") || l.contains("sensory") { cond = "Sensory Processing Disorder (SPD)" }
            else if l.contains("gastro") || l.contains("constipation") || l.contains("gerd") { cond = "Gastrointestinal Issues (constipation, GERD, food allergies)" }
            else if l.contains("sleep") || l.contains("insomnia") { cond = "Sleep Disorders (insomnia, night waking, sleep apnea)" }
            else if l.contains("genetic") || l.contains("down") || l.contains("rett") { cond = "Genetic Conditions (Down Syndrome, Fragile X, Rett)" }
            else if l.contains("hearing") { cond = "Hearing Impairment" }
            else if l.contains("visual") { cond = "Visual Impairment / Cortical Visual Impairment" }
            else if l.contains("speech") || l.contains("language") { cond = "Speech / Language Delay" }
            else if l.contains("motor") || l.contains("dyspraxia") { cond = "Motor Coordination / Dyspraxia" }
            else if l.contains("asthma") { cond = "Asthma" }
            else if l.contains("diabetes") { cond = "Diabetes" }
            else if l.contains("heart") { cond = "Heart Disease" }
            else if l.contains("dental") { cond = "Dental Treatment History" }
            else if l.contains("allergies") { cond = "Gastrointestinal Issues (constipation, GERD, food allergies)" }
            else { return }
            
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "MedicalHistory_Conditions") {
                updateMedicalCondition(pid: pid, conditionName: cond, isActive: true)
            }

        // MARK: School Complaints
        case let label where label.hasPrefix("SC_") || label.hasPrefix("SchoolComplaints_"):
            var field = ""; var value = ""
            switch label {
            case "SC_Attention", "SchoolComplaints_Attention": field = "Attention and focus in class"; value = "Poor attention/easily distracted"
            case "SC_Sitting", "SchoolComplaints_Sitting": field = "Ability to sit quietly"; value = "Fidgety/Unable to sit still"
            case "SC_Transition_Difficulty", "SchoolComplaints_Transitions": field = "Difficulty with transitions (e.g., classroom to playground)?"; value = "Struggles with transitions"
            case "SC_Handwriting", "SchoolComplaints_Handwriting": field = "Handwriting difficulties (speed, legibility)?"; value = "Poor legibility / slow speed"
            default: return
            }
            let lockKey = "SchoolComplaints_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateSchoolComplaintsField(pid: pid, fieldName: field, value: value)
            }

        // MARK: Developmental History (Language, Social, Self-Care)
        case let label where label.hasPrefix("LC_") || label.hasPrefix("Developmental_Language_"):
            var f = ""; var v = ""
            switch label {
            case "LC_Babbling", "Developmental_Language_Babbling": f = "Age of first babbling"; v = "Delayed (>9 months)"
            case "LC_FirstWord", "Developmental_Language_FirstWord": f = "Age of first meaningful word"; v = "Delayed (>15 months)"
            case "LC_Sentences", "Developmental_Language_Sentences": f = "Age of speaking in full sentences"; v = "Delayed (>3 years)"
            default: return
            }
            let lockKey = "Language&Communication_\(String(f.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateTextDictionary(pid: pid, subSection: "Language & Communication", fieldName: f, value: v)
            }

        case let label where label.hasPrefix("SM_") || label.hasPrefix("Developmental_Social_"):
            var f = ""; var v = ""
            switch label {
            case "SM_EyeContact", "Developmental_Social_EyeContact": f = "Eye contact (consistent, fleeting, poor)"; v = "Poor/fleeting eye contact"
            case "SM_Name", "Developmental_Social_Name": f = "Response to name being called"; v = "Inconsistent or no response"
            case "SM_Play_Parallel", "Developmental_Social_Play": f = "Type of play (Solitary, Parallel, Cooperative)"; v = "Parallel play"
            default: return
            }
            let lockKey = "SocialMilestones_\(String(f.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateTextDictionary(pid: pid, subSection: "Social Milestones", fieldName: f, value: v)
            }

        case let label where label.hasPrefix("SCare_") || label.hasPrefix("Developmental_SelfCare_"):
            var f = ""; var v = ""
            switch label {
            case "SCare_Spoon", "Developmental_SelfCare_Spoon": f = "Age of holding spoon independently"; v = "Delayed"
            case "SCare_Toilet", "Developmental_SelfCare_Toilet": f = "Age of toilet training (daytime)"; v = "Delayed / Not achieved"
            default: return
            }
            let lockKey = "Self-CareMilestones_\(String(f.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateTextDictionary(pid: pid, subSection: "Self-Care Milestones", fieldName: f, value: v)
            }

        // MARK: Cognitive Labels (Specific & Granular)
        case let label where label.hasPrefix("Cognitive_"):
            switch label {
            // Q2: Symbolic/Pretend Play (Options: On time, Delayed, Not achieved, Unsure)
            case "Cognitive_PretendPlay_Yes", "Cognitive_PretendPlay_OnTime":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q2") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 1, optionIndex: 0)
                }
            case "Cognitive_PretendPlay_Delayed":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q2") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 1, optionIndex: 1)
                }
            case "Cognitive_PretendPlay_No", "Cognitive_PretendPlay_NotAchieved":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q2") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 1, optionIndex: 2)
                }

            // Q4: Matching/Sorting (Options: Age appropriate, Emerging, Not achieved, Unsure)
            case "Cognitive_Matching_Yes", "Cognitive_Matching_AgeAppropriate":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q4") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 3, optionIndex: 0)
                }
            case "Cognitive_Matching_Emerging":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q4") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 3, optionIndex: 1)
                }
            case "Cognitive_Matching_No", "Cognitive_Matching_NotAchieved":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q4") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 3, optionIndex: 2)
                }

            // Q7: Letters/Numbers (Options: Yes-most, Some, No, Not age appropriate)
            case "Cognitive_Letters_Yes", "Cognitive_Letters_Most":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q7") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 6, optionIndex: 0)
                }
            case "Cognitive_Letters_Some":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q7") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 6, optionIndex: 1)
                }
            case "Cognitive_Letters_No":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q7") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 6, optionIndex: 2)
                }

            // Q3: Cause and Effect (Options: Yes, Emerging, Not observed, Unsure)
            case "Cognitive_CauseEffect_Yes":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q3") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 2, optionIndex: 0)
                }
            case "Cognitive_CauseEffect_Emerging":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q3") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 2, optionIndex: 1)
                }
            case "Cognitive_CauseEffect_No":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q3") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 2, optionIndex: 2)
                }

            // Q1: Object Permanence (Options: On time, Delayed, Not achieved, Unsure)
            case "Cognitive_ObjectPermanence_Yes", "Cognitive_ObjectPermanence_OnTime":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q1") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 0, optionIndex: 0)
                }
            case "Cognitive_ObjectPermanence_Delayed":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q1") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 0, optionIndex: 1)
                }
            case "Cognitive_ObjectPermanence_No":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q1") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 0, optionIndex: 2)
                }

            // Q5: Possession (Options: Yes, Emerging, Not observed, Unsure)
            case "Cognitive_Possession_Yes":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q5") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 4, optionIndex: 0)
                }
            case "Cognitive_Possession_No":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q5") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 4, optionIndex: 2)
                }

            // Q6: Name Recognition (Options: Yes, Partially, No, Unsure)
            case "Cognitive_NameRecognition_Yes":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q6") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 5, optionIndex: 0)
                }
            case "Cognitive_NameRecognition_Partial":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q6") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 5, optionIndex: 1)
                }
            case "Cognitive_NameRecognition_No":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "CognitiveSkills_Q6") {
                    updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: 5, optionIndex: 2)
                }

            // Sensory Mapping for MultiStep (Options: Yes, Sometimes, No)
            case "Cognitive_FollowsMultiStep_Yes":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "SensoryProfile_Attention_Q3") {
                    updateSensoryAnswer(pid: pid, sectionIndex: 9, questionIndex: 3, optionIndex: 0)
                }
            case "Cognitive_FollowsMultiStep_Sometimes":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "SensoryProfile_Attention_Q3") {
                    updateSensoryAnswer(pid: pid, sectionIndex: 9, questionIndex: 3, optionIndex: 1)
                }
            case "Cognitive_FollowsMultiStep_No":
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: "SensoryProfile_Attention_Q3") {
                    updateSensoryAnswer(pid: pid, sectionIndex: 9, questionIndex: 3, optionIndex: 2)
                }
            default: break
            }

        // MARK: Daily Living
        case let label where label.hasPrefix("DL_") || label.hasPrefix("DailyLiving_"):
            var sub = ""; var f = ""; var v = ""
            switch label {
            case "DL_Feeding_Selectivity", "DailyLiving_Feeding_Selectivity": sub = "Feeding"; f = "Food selectivity (picky eater, textures ignored)?"; v = "Picky eater / Food aversions"
            case "DL_Toilet_Flush", "DailyLiving_Toileting_FearOfFlush": sub = "Toileting"; f = "Does the child flush without distress?"; v = "Distressed by flush sound"
            case "DL_Sleep_Onset", "DailyLiving_Sleep_DifficultyOnset": sub = "Sleep"; f = "Sleep onset — time taken to fall asleep"; v = "Prolonged onset (>1 hour)"
            case "DailyLiving_Sleep_Good": sub = "Sleep"; f = "Night wakings — frequency and duration"; v = "Sleeps through the night / No issues"
            default: return
            }
            let lockKey = "\(sub)_\(String(f.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateTextDictionary(pid: pid, subSection: sub, fieldName: f, value: v)
            }

        // MARK: Family & Social
        case let label where label.hasPrefix("FH_") || label.hasPrefix("FamilyHistory_"):
            var f = ""; var v = ""
            switch label {
            case "FH_Neurodevelopmental", "FamilyHistory_Neurodevelopmental": f = "Any family member diagnosed with ASD, ADHD, or learning disabilities?"; v = "Yes - Positive family history"
            default: return
            }
            let lockKey = "FamilyHistory_\(String(f.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateTextDictionary(pid: pid, subSection: "Family History", fieldName: f, value: v)
            }

        case let label where label.hasPrefix("SE_") || label.hasPrefix("SocialEnvironmental_"):
            var f = ""; var v = ""
            switch label {
            case "SE_ScreenTime", "SocialEnvironmental_ScreenTime": f = "Screen time per day (type: TV, tablet, phone)"; v = "High screen time (Tablet/Phone)"
            default: return
            }
            let lockKey = "Social&Environmental_\(String(f.prefix(15)).replacingOccurrences(of: " ", with: ""))"
            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                updateTextDictionary(pid: pid, subSection: "Social & Environmental", fieldName: f, value: v)
            }

        default:
            print("ℹ️ No logic mapped for label: \(predictedLabel)")
        }
    }
private func updateBirthHistoryField(pid: String, fieldName: String, value: String) {
            let session = AssessmentSessionManager.shared.getBirthHistory(for: pid)
            var dict = session.data
            
            if dict[fieldName] != value {
                dict[fieldName] = value
                AssessmentSessionManager.shared.updateBirthHistory(for: pid, data: dict, didFetch: true)
                broadcastUpdate()
            }
        }
    private func updateMedicalCondition(pid: String, conditionName: String, isActive: Bool) {
        // 1. Get existing medical history session data
        let currentHistory = AssessmentSessionManager.shared.getMedicalHistory(for: pid)
        var updatedConditions = currentHistory.conditions // This is a Set<String>
        
        // 2. Only update if the value is actually changing
        let alreadyActive = updatedConditions.contains(conditionName)
        
        if isActive && !alreadyActive {
            updatedConditions.insert(conditionName)
            
            // 3. Save back to Session Manager
            AssessmentSessionManager.shared.updateMedicalHistory(
                for: pid,
                conditions: updatedConditions,
                notes: currentHistory.notes,
                didFetch: true
            )
            
            // 4. Notify UI to refresh the checkmarks
            broadcastUpdate()
        }
    }
    
    private func updateSchoolComplaintsField(pid: String, fieldName: String, value: String) {
        let session = AssessmentSessionManager.shared.getSchoolComplaints(for: pid)
        var dict = session.data
        if dict[fieldName] != value {
            dict[fieldName] = value
            AssessmentSessionManager.shared.updateSchoolComplaints(for: pid, data: dict, didFetch: true)
            broadcastUpdate()
        }
    }
    
    // MARK: - Sensory Logic Helpers
        
        private func getSensorySectionTitle(index: Int) -> String {
            let titles = [
                "Tactile (Touch)",
                "Proprioception",
                "Vestibular (Movement & Balance)",
                "Auditory (Sound)",
                "Visual",
                "Olfactory (Smell)",
                "Gustatory (Taste)",
                "Interoception (Internal Signals)",
                "Behavioral Observations",
                "Attention & Executive Function"
            ]
            return (index >= 0 && index < titles.count) ? titles[index] : "UnknownSection"
        }

        private func getSensoryQuestionText(sIdx: Int, qIdx: Int) -> String {
            switch sIdx {
            case 0: // Tactile (Touch)
                let questions = [
                    "Resists light touch but tolerates deep pressure",
                    "Avoids certain clothing textures (tags, seams, fabrics)",
                    "Dislikes being touched by others",
                    "Seeks out tactile stimulation (rubbing surfaces)",
                    "Difficulty with grooming (haircuts, nails, face washing)",
                    "Food texture aversions (refuses soft/lumpy/mixed)",
                    "Walks barefoot or refuses to walk barefoot",
                    "Reacts strongly to pain differently than expected"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 1: // Proprioception
                let questions = [
                    "Seeks heavy work (pushing, pulling, crashing)",
                    "Hugs too tightly",
                    "Chews on non-food items (pencils, clothing, hands)",
                    "Poor awareness of force used (breaks toys)",
                    "Leans against walls or people frequently",
                    "Prefers tight clothing or weighted blankets"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 2: // Vestibular (Movement & Balance)
                let questions = [
                    "Seeks excessive movement (spinning, swinging, rocking)",
                    "Becomes dizzy easily or not at all with spinning",
                    "Fears heights or movement (car sickness, fear of swings)",
                    "Poor balance (frequent falls)",
                    "Rocks body when sitting",
                    "Avoids playground equipment"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 3: // Auditory (Sound)
                let questions = [
                    "Covers ears in response to certain sounds",
                    "Distress from specific sounds (vacuum, dryer, alarm)",
                    "Seems not to hear when called but responds to other sounds",
                    "Seeks loud sounds or makes loud noises",
                    "Distracted by background noise"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 4: // Visual
                let questions = [
                    "Looks at objects from unusual angles",
                    "Stares at lights or spinning objects",
                    "Covers one eye or squints frequently",
                    "Distracted by visual clutter",
                    "Lines up objects rather than playing with them",
                    "Difficulty with visual tracking"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 5: // Olfactory (Smell)
                let questions = [
                    "Smells food before eating it",
                    "Smells people, objects, or environments excessively",
                    "Reacts strongly to certain smells"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 6: // Gustatory (Taste)
                let questions = [
                    "Extremely limited food repertoire",
                    "Refuses foods based on taste/texture/temperature",
                    "Gags or vomits in response to certain foods",
                    "Craves very spicy or very bland foods"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 7: // Interoception (Internal Signals)
                let questions = [
                    "Recognizes hunger or fullness",
                    "Recognizes need to use toilet",
                    "Recognizes pain appropriately",
                    "Recognizes fatigue, fear, or anxiety"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 8: // Behavioral Observations
                let questions = [
                    "Engages in self-stimulatory behaviors (stimming)",
                    "Has rigid routines; distressed when disrupted",
                    "Has intense, narrow interests",
                    "Aggressive behaviors (hitting, biting, kicking)",
                    "Self-injurious behavior (head-banging, biting self)",
                    "Difficulty with transitions between activities",
                    "Demonstrates frustration tolerance",
                    "Has meltdowns vs. shutdowns"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            case 9: // Attention & Executive Function
                let questions = [
                    "Attends to preferred activity for extended time",
                    "Attends to non-preferred activity",
                    "Shifts attention easily between tasks",
                    "Follows multi-step instructions",
                    "Plans and sequences tasks independently",
                    "Initiates tasks without prompting",
                    "Difficulty stopping an activity to move on"
                ]
                return (qIdx >= 0 && qIdx < questions.count) ? questions[qIdx] : ""
                
            default:
                return ""
            }
        }
    
    // MARK: - Update Helpers
    
    private func updateRadioAnswer(pid: String, assessment: String, questionIndex: Int, optionIndex: Int) {
        var currentAnswers = AssessmentSessionManager.shared.getTestAnswers(for: pid)[assessment] as? [Int: Int] ?? [:]
        if currentAnswers[questionIndex] != optionIndex {
            currentAnswers[questionIndex] = optionIndex
            AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: assessment, value: currentAnswers)
            broadcastUpdate()
        }
    }
    // Add this to AIAssistManager.swift
    func simulateSpeech(text: String) {
        print("🧪 Simulating Speech: \(text)")
        // This calls your existing CoreML/Keyword routing logic
        self.routeAIInsight(text: text)
    }
    
    private func updateSensoryAnswer(pid: String, sectionIndex: Int, questionIndex: Int, optionIndex: Int) {
        var allSensory = AssessmentSessionManager.shared.getTestAnswers(for: pid)["Sensory Profile"] as? [Int: [Int: Int]] ?? [:]
        if allSensory[sectionIndex] == nil { allSensory[sectionIndex] = [:] }
        
        if allSensory[sectionIndex]?[questionIndex] != optionIndex {
            allSensory[sectionIndex]?[questionIndex] = optionIndex
            AssessmentSessionManager.shared.updateTestAnswer(for: pid, key: "Sensory Profile", value: allSensory)
            broadcastUpdate()
        }
    }
    
    private func updateTextDictionary(pid: String, subSection: String, fieldName: String, value: String) {
        let session = AssessmentSessionManager.shared.getSubSectionData(for: pid, subSection: subSection)
        var dict = session.data
        
        if dict[fieldName] != value {
            dict[fieldName] = value
            AssessmentSessionManager.shared.updateSubSectionData(for: pid, subSection: subSection, data: dict, didFetch: true)
            broadcastUpdate()
        }
    }
    
    private func broadcastUpdate() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("AI_Assessment_Updated"), object: nil)
        }
    }
}
