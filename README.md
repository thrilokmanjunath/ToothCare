<div align="center">
  <h1>🦷 ToothCare: AI Digital Twin & Treatment Planner</h1>
  <p><strong>Next-Generation 3D Dental Charting built with SwiftUI, SceneKit, and Natural Language Processing.</strong></p>
</div>

<br>

ToothCare is an advanced, interactive clinical application designed to revolutionize how dentists and patients visualize oral health. It goes beyond simple 2D charts by creating a **3D Digital Twin** of a patient's mouth that instantly responds to AI-driven clinical summaries.

---

## 🌟 Key Features

### 🧠 AI NLP Engine (Magic Wand)
Dictate or type clinical summaries like *"Severe periodontitis on tooth 24 and an impacted wisdom tooth on 32."* The on-device NLP engine automatically extracts medical terminology, translates it to anatomical tooth numbers, and instantly updates the 3D model with accurate disease markers.

### 🎨 Advanced 3D Rendering & Materials
Leverages **SceneKit** physically-based rendering (PBR) to map diseases directly onto the 3D models with stunning realism:
*   **Periodontitis (Gum Disease):** Gums turn deep, inflamed red.
*   **Abscess / Infections:** Emissive, glowing green spheres indicate active infections.
*   **Impacted Wisdom Teeth:** Models rotate and become semi-transparent purple to simulate impaction.
*   **Crowns / Implants:** Teeth transform into highly reflective, shiny metallic materials.

### 📋 Intelligent Treatment Planner
ToothCare acts as a medical assistant. When a disease is mapped, the app automatically generates the standard clinical procedure (e.g., *Abscess ➔ Root Canal Therapy & Antibiotics*). 

### 👥 Patient Management System
*   Create, save, and switch between hundreds of patient profiles instantly.
*   Each patient maintains an independent 3D digital twin and clinical history.
*   Active patient details are dynamically tracked across the UI.

### 📄 Automated PDF Export
Generate formal, legally identifiable medical invoices in a single tap. The PDF includes the active patient's name, age, 3D chart summary, clinical notes, and the AI-generated Treatment Plan.

### 📱 Stunning Glassmorphism UI
Built entirely in **SwiftUI** with iOS 15+ `ultraThinMaterial` blurs, sleek gradients, dynamic toolbars, and intuitive gestures (pinch-to-zoom, pan, X-Ray toggle).

---

## 🛠️ Technical Stack
*   **SwiftUI:** For a modern, declarative, reactive user interface.
*   **SceneKit:** For complex 3D node hierarchies, custom lighting rigs (ambient + directional shadows), and PBR material swapping.
*   **Observation Framework (`@Observable`):** For massive performance gains in state management over traditional `@Published` architectures.
*   **Regex / NLP:** For processing and mapping clinical strings into structured 3D actions.

---

## 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/thrilokmanjunath/ToothCare.git
   ```
2. Open `ToothCare.xcodeproj` in Xcode (version 15+ recommended).
3. Select your target device (iPhone Simulator or physical device).
4. Hit **Cmd + R** to build and run!

---

<div align="center">
  <p><i>Developed to push the boundaries of clinical software design.</i></p>
</div>
