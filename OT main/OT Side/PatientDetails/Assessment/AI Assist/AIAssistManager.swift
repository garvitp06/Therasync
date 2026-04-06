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
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }
    
    private func beginAudioRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        // Setting to false means it will process full chunks of thought rather than every single syllable,
        // which gives the CoreML model better context to predict from.
        recognitionRequest.shouldReportPartialResults = false
        
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
                // Get the transcribed sentence
                let spokenText = result.bestTranscription.formattedString
                print("👂 AI Heard: \(spokenText)")
                self.routeAIInsight(text: spokenText)
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
                if self.isListening { self.beginAudioRecording() } // Auto-restart seamlessly
            }
        }
    }

    // MARK: - The AI Router
        private func routeAIInsight(text: String) {
            guard let pid = currentPatientID, let classifier = textClassifier else { return }
            guard let predictedLabel = classifier.predictedLabel(for: text) else { return }
            
            print("🗣️ Heard: '\(text)' ---> 🤖 Predicted: \(predictedLabel)")
            
            let components = predictedLabel.components(separatedBy: "_")
            
            // --- 1. HANDLE DYNAMIC ASSESSMENTS (GM, FM, COG, ADOS) ---
            // Labels look like: GM_Q5_1 or ADOS_Q10_3
            if components.count == 3 {
                let prefix = components[0]
                let qNumStr = components[1].replacingOccurrences(of: "Q", with: "")
                
                if let qNum = Int(qNumStr), let optIdx = Int(components[2]) {
                    let qIdx = qNum - 1
                    
                    switch prefix {
                    case "GM":
                        let key = "GrossMotor_Q\(qNum)"
                        if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                            updateRadioAnswer(pid: pid, assessment: "Gross Motor Skills", questionIndex: qIdx, optionIndex: optIdx)
                        }
                    case "FM":
                        let key = "FineMotor_Q\(qNum)"
                        if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                            updateRadioAnswer(pid: pid, assessment: "Fine Motor Skills", questionIndex: qIdx, optionIndex: optIdx)
                        }
                    case "COG":
                        let key = "CognitiveSkills_Q\(qNum)"
                        if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                            updateRadioAnswer(pid: pid, assessment: "Cognitive Skills", questionIndex: qIdx, optionIndex: optIdx)
                        }
                    case "ADOS":
                        let key = "ADOS_Q\(qNum)"
                        if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: key) {
                            updateRadioAnswer(pid: pid, assessment: "ADOS", questionIndex: qIdx, optionIndex: optIdx)
                        }
                    default:
                        break
                    }
                    
                    // If it matched one of the above prefixes, return early so it doesn't run the code below
                    if ["GM", "FM", "COG", "ADOS"].contains(prefix) {
                        return
                    }
                }
            }
            
            // --- 2. HANDLE SPECIFIC LABELS (Sensory, Birth, Medical, School) ---
            switch predictedLabel {
                
            // MARK: Sensory Profile
            case let label where label.hasPrefix("SP_"):
                if components.count == 4,
                   let sIdx = Int(components[1]), let qIdx = Int(components[2]), let oIdx = Int(components[3]) {
                    
                    let sectionTitle = self.getSensorySectionTitle(index: sIdx)
                    let questionText = self.getSensoryQuestionText(sIdx: sIdx, qIdx: qIdx)
                    let shortQuestion = String(questionText.prefix(20)).replacingOccurrences(of: " ", with: "")
                    let lockKey = "SensoryProfile_\(sectionTitle)_\(shortQuestion)"
                    
                    if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                        updateSensoryAnswer(pid: pid, sectionIndex: sIdx, questionIndex: qIdx, optionIndex: oIdx)
                    }
                }

            // MARK: Birth History
            case let label where label.hasPrefix("BH_"):
                var field = ""; var value = ""
                switch label {
                case "BH_Prenatal_Planned_No": field = "Was the pregnancy planned?"; value = "No"
                case "BH_Prenatal_Planned_Yes": field = "Was the pregnancy planned?"; value = "Yes"
                case "BH_Birth_Type_NVD": field = "Type of delivery (NVD / C-section / Assisted)"; value = "NVD"
                case "BH_Birth_Gestation_Preterm": field = "Gestation at birth (term 37–42 weeks / preterm / post-term)"; value = "Preterm"
                case "BH_Neonatal_Jaundice_Yes": field = "Any jaundice (neonatal hyperbilirubinemia)?"; value = "Yes (reported by parent)"
                default: return
                }
                let lockKey = "BirthHistory_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                    updateBirthHistoryField(pid: pid, fieldName: field, value: value)
                }

            // MARK: Medical History
            case let label where label.hasPrefix("Medical_"):
                var conditionName = ""
                switch label {
                case "Medical_ASD": conditionName = "Autism Spectrum Disorder (ASD)"
                case "Medical_ADHD": conditionName = "ADHD — Combined, Inattentive, or Hyperactive-Impulsive"
                case "Medical_Epilepsy": conditionName = "Epilepsy / Seizure Disorder"
                case "Medical_Anxiety": conditionName = "Anxiety Disorders"
                case "Medical_SPD": conditionName = "Sensory Processing Disorder (SPD)"
                case "Medical_Sleep": conditionName = "Sleep Disorders (insomnia, night waking, sleep apnea)"
                case "Medical_GI": conditionName = "Gastrointestinal Issues (constipation, GERD, food allergies)"
                default: return
                }
                let lockKey = "MedicalHistory_\(conditionName.replacingOccurrences(of: " ", with: ""))"
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                    updateMedicalCondition(pid: pid, conditionName: conditionName, isActive: true)
                }

            // MARK: School Complaints
            case let label where label.hasPrefix("SC_"):
                var field = ""; var value = ""
                switch label {
                case "SC_CircleTime_Difficulty": field = "Can the child sit in a group at circle time?"; value = "No - reported difficulty"
                case "SC_Transition_Difficulty": field = "Can the child transition between activities with the class?"; value = "Struggles with transitions"
                case "SC_Belongings_Difficulty": field = "Can the child manage their belongings (school bag, lunch box, water bottle)?"; value = "Needs assistance"
                case "SC_Cafeteria_Overload": field = "How does the child behave in the cafeteria (noise, food)?"; value = "Overwhelmed by noise"
                case "SC_Plan_IEP": field = "Does the child have an IEP or 504 Plan?"; value = "Yes - IEP"
                case "SC_Plan_504": field = "Does the child have an IEP or 504 Plan?"; value = "Yes - 504 Plan"
                default: return
                }
                let lockKey = "SchoolComplaints_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                    updateSchoolComplaintsField(pid: pid, fieldName: field, value: value)
                }
                // MARK: - Language & Communication
            case let label where label.hasPrefix("LC_"):
                            var field = ""; var value = ""
                            switch label {
                            case "LC_Cooing_OnTime": field = "Cooing (~2 months)"; value = "On time"
                            case "LC_Babbling_Delayed": field = "Babbling (consonant-vowel sounds, ~6 months)"; value = "Delayed"
                            case "LC_FirstWord_OnTime": field = "First meaningful single word (expected by 12 months)"; value = "On time"
                            case "LC_ThreeWord_Yes": field = "Three-word sentences (~24–30 months)"; value = "Yes - present"
                            case "LC_Regression_Yes": field = "Has the child lost speech or skills they had previously?"; value = "Yes - skill regression noted"
                            case "LC_Echolalia_Yes": field = "Is speech used functionally or echolalia (immediate/delayed)?"; value = "Predominantly echolalia"
                            case "LC_Gestures_Yes": field = "Does the child use gestures (pointing, waving)?"; value = "Yes - points/waves"
                            case "LC_NameResponse_No": field = "Does the child respond to their name when called?"; value = "Inconsistent or absent"
                            case "LC_InitiateConv_No": field = "Does the child initiate conversation?"; value = "Rarely/Never"
                            default: return
                            }
                            
                            // Build lock key: SubSectionName_First15Chars (No Spaces)
                            let lockKey = "Language&Communication_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                                updateTextDictionary(pid: pid, subSection: "Language & Communication", fieldName: field, value: value)
                            }

                        // MARK: - Social Milestones
            case let label where label.hasPrefix("SM_"):
                            var field = ""; var value = ""
                            switch label {
                            case "SM_Smile_OnTime": field = "Social smile (~6 weeks)"; value = "On time"
                            case "SM_Stranger_Extreme": field = "Stranger anxiety (~6–8 months)"; value = "Extreme anxiety"
                            case "SM_JointAttention_Absent": field = "Joint attention — pointing to share interest (~9–14 months)"; value = "Absent"
                            case "SM_Play_Parallel": field = "Play stage (parallel / associative / cooperative)"; value = "Parallel play"
                            case "SM_EyeContact_Absent": field = "Eye contact — spontaneous or absent?"; value = "Poor/Absent"
                            case "SM_Affection_Yes": field = "Does the child show affection to caregivers?"; value = "Yes"
                            case "SM_Separation_Extreme": field = "Separation anxiety — typical or extreme?"; value = "Extreme"
                            default: return
                            }
                            
                            let lockKey = "SocialMilestones_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                                updateTextDictionary(pid: pid, subSection: "Social Milestones", fieldName: field, value: value)
                            }

                        // MARK: - Self-Care Milestones
            case let label where label.hasPrefix("SCare_"):
                            var field = ""; var value = ""
                            switch label {
                            case "SCare_FingerFeed_Yes": field = "Feeding self with fingers (~12 months)"; value = "Yes"
                            case "SCare_Spoon_Messy": field = "Spoon use (~18 months)"; value = "Emerging / Messy"
                            case "SCare_Cup_No": field = "Drinking from open cup (~12–18 months)"; value = "No - uses sippy/bottle"
                            case "SCare_Toilet_DayOnly": field = "Toilet training — age started, current status (daytime/nighttime)"; value = "Daytime trained only"
                            case "SCare_Dressing_NeedsHelp": field = "Dressing: undressing before dressing; sequence of clothing"; value = "Requires full assistance"
                            case "SCare_Bathing_PoorTolerance": field = "Bathing: tolerance, independent steps"; value = "Poor tolerance / distress"
                            case "SCare_Teeth_PoorTolerance": field = "Toothbrushing: tolerance, technique"; value = "Poor tolerance / distress"
                            default: return
                            }
                            
                            let lockKey = "Self-CareMilestones_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                    updateTextDictionary(pid: pid, subSection: "Self-Care Milestones", fieldName: field, value: value)
                }
                // MARK: - Daily Living (Feeding, Dressing, Bathing, Toileting, Sleep)
            case let label where label.hasPrefix("DL_"):
                            var subSection = ""
                            var field = ""
                            var value = ""
                            
                            switch label {
                            // Feeding
                            case "DL_Feed_Repertoire":
                                subSection = "Feeding"; field = "Food repertoire: how many foods accepted? (less than 20 = concern)"; value = "Limited (<20 items)"
                            case "DL_Feed_Texture":
                                subSection = "Feeding"; field = "Textures accepted (puree, soft, crunchy, mixed)"; value = "Texture aversions noted"
                            case "DL_Feed_Temp":
                                subSection = "Feeding"; field = "Temperature preferences"; value = "Strong temperature preference"
                            case "DL_Feed_Stress":
                                subSection = "Feeding"; field = "Is mealtime a positive or stressful experience?"; value = "Stressful experience"
                                
                            // Dressing
                            case "DL_Dress_FrontBack":
                                subSection = "Dressing"; field = "Can the child identify front and back of clothing?"; value = "Difficulty identifying"
                            case "DL_Dress_Fasteners":
                                subSection = "Dressing"; field = "Can the child manage fasteners (velcro, buttons, zippers, snaps, laces)?"; value = "Needs assistance"
                            case "DL_Dress_Resistance":
                                subSection = "Dressing"; field = "Does the child resist certain clothing items? Why?"; value = "Yes - sensory resistance"
                                
                            // Bathing & Hygiene
                            case "DL_Bath_Tolerates":
                                subSection = "Bathing & Hygiene"; field = "Tolerates bathing? Specific aversions (water on face, shampoo, soap)?"; value = "Aversion to water on face/head"
                            case "DL_Bath_Teeth":
                                subSection = "Bathing & Hygiene"; field = "Toothbrushing tolerance (texture of bristle, flavor, duration)"; value = "Poor tolerance"
                            case "DL_Bath_Nails":
                                subSection = "Bathing & Hygiene"; field = "Nail cutting — reaction?"; value = "Extreme distress/resistance"
                                
                            // Toileting
                            case "DL_Toilet_Trained":
                                subSection = "Toileting"; field = "Currently toilet trained (day/night)?"; value = "Daytime trained only"
                            case "DL_Toilet_Wiping":
                                subSection = "Toileting"; field = "Does the child wipe adequately?"; value = "Requires assistance"
                            case "DL_Toilet_Flush":
                                subSection = "Toileting"; field = "Does the child flush without distress?"; value = "Distressed by flush sound"
                                
                            // Sleep
                            case "DL_Sleep_Onset":
                                subSection = "Sleep"; field = "Sleep onset — time taken to fall asleep"; value = "Prolonged onset (>1 hour)"
                            case "DL_Sleep_Wakings":
                                subSection = "Sleep"; field = "Night wakings — frequency and duration"; value = "Frequent night wakings"
                            case "DL_Sleep_Meds":
                                subSection = "Sleep"; field = "Use of melatonin or other sleep aids?"; value = "Yes - Melatonin/Sleep aid used"
                                
                            default: return
                            }
                            
                            // Build lock key dynamically based on the SubSection and Field Name
                            let lockKey = "\(subSection)_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                            
                            // Check Lock and Update
                            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                                updateTextDictionary(pid: pid, subSection: subSection, fieldName: field, value: value)
                            }

                // MARK: - Family History
            case let label where label.hasPrefix("FH_"):
                            var field = ""
                            var value = ""
                            
                            switch label {
                            case "FH_Neurodevelopmental":
                                field = "Any family member diagnosed with ASD, ADHD, or learning disabilities?"; value = "Yes - Positive family history"
                            case "FH_Consanguinity":
                                field = "Consanguinity (are parents related by blood)?"; value = "Yes - Consanguineous parents"
                            case "FH_Siblings":
                                field = "Sibling details (ages, any special needs?)"; value = "Yes - Sibling has special needs"
                            case "FH_Caregiver":
                                field = "Who is the primary caregiver?"; value = "Grandparent / Extended family"
                            case "FH_Stressors":
                                field = "Any recent family stressors (divorce, death, relocation, financial stress)?"; value = "Yes - Recent major stressor"
                            default: return
                            }
                            
                            // Build the lock key (e.g., "FamilyHistory_Anyfamilymember")
                            let lockKey = "FamilyHistory_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                            
                            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                                updateTextDictionary(pid: pid, subSection: "Family History", fieldName: field, value: value)
                            }

                        // MARK: - Social & Environmental
            case let label where label.hasPrefix("SE_"):
                            var field = ""
                            var value = ""
                            
                            switch label {
                            case "SE_HomeType":
                                field = "Type of home (house/apartment, urban/rural)"; value = "Apartment / Urban"
                            case "SE_ScreenTime":
                                field = "Screen time per day (type: TV, tablet, phone)"; value = "High screen time (Tablet/Phone)"
                            case "SE_SchoolType":
                                field = "Childcare or school type (mainstream, special needs, home-schooled)"; value = "Mainstream school"
                            case "SE_Transportation":
                                field = "Transportation access"; value = "Transportation barriers noted"
                            default: return
                            }
                            
                            // Build the lock key (e.g., "Social&Environmental_Typeofhome(hous")
                            let lockKey = "Social&Environmental_\(String(field.prefix(15)).replacingOccurrences(of: " ", with: ""))"
                            
                            if !AssessmentSessionManager.shared.isFieldLocked(for: pid, key: lockKey) {
                                updateTextDictionary(pid: pid, subSection: "Social & Environmental", fieldName: field, value: value)
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
