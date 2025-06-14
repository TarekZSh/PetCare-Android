# 🐾 PetCare

**PetCare** is a comprehensive Android app designed to help pet owners manage their pets' health and well-being. 
With features ranging from medical history tracking to real-time reminders and vet integration, PetCare offers a complete digital assistant for responsible pet care.

---

## 📱 Features

- ✅ **User Authentication**
  - Secure Google Sign-In integration

- 🐶 **Pet Profile Management**
  - Add pets with details like breed, age, gender, and photo
  - Track allergies, medications, and special notes
  - Set status updates (e.g., "Open to walk", "Open to breeding")

- 🗂️ **Health & Medical Records**
  - Maintain medical history for each pet
  - Record allergies, vaccinations, and chronic conditions
  - Add vet visit notes

- 🗓️ **Reminders**
  - Schedule reminders for vaccinations, vet appointments, and medications

- 👩‍⚕️ **Vet Profiles**
  - Store and view vet details
  - See which pets are treated by which vets

- ❤️ **Favorites List**
  - Bookmark preferred vets or services

- 📰 **Pet Feed**  
  Browse pet care content, updates, and community news in a central feed.

- 💬 **Chatbot Assistant**
  - AI-powered chatbot to answer questions and assist with pet care tasks

- ☁️ **Cloud Storage**  
  - All pet data is synced using **Firebase Firestore** and media files are stored in **Firebase Storage**.

---

## 🛠️ Built With

- 📱 Android (Kotlin/Java)  
- 🔥 Firebase  
  - Authentication (Google Sign-In)  
  - Firestore (for users, pets, and vets data)  
  - Storage (for pet images and documents)  
- 🎨 Material Design for modern UI/UX  
- 🤖 AI-powered chatbot powered by **Google Gemini API**

---

## 🚀 Getting Started

1. **Clone the repo**

   ```bash
   git clone https://github.com/yourusername/PetCare.git
   cd PetCare
2. **Open the project** in Android Studio or your preferred Flutter IDE.

3. **Set up Firebase:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new Firebase project.
   - Add your Android app with the correct package name.
   - Download `google-services.json` and place it in `android/app/`.

4. **Enable services in Firebase:**
   - 🔐 Authentication → Enable **Google Sign-In**
   - 🔥 Firestore Database → Create collections: `Users`, `Pets`, `Vets`
   - ☁️ Firebase Storage → Enable for media and documents

5. **Run the app:**

   ```bash
   flutter pub get
   flutter run

---

## 🧱 Firebase Structure Overview

### Users Collection
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "favorites": ["vetId1", "vetId2"]
}
```
### Pets Collection
```json
{
  "ownerId": "string",
  "name": "string",
  "age": "int",
  "breed": "string",
  "allergies": ["string"],
  "medications": ["string"],
  "notes": "string",
  "vetId": "string",
  "status": {
    "openToWalk": true,
    "openToBreeding": false
  }
}
```
### Vets Collection
```json
{
  "vetId": "string",
  "name": "string",
  "specialization": "string",
  "treatedPets": ["petId1", "petId2"]
}
```

---

## 📸 Screenshots

### 🐾 Pet Profile  
Manage each pet's medical history, status, and personal info.  
<img src="pet_care_app/assets/screenshots/PetProfile.jpg" alt="Pet Profile" height="650"/>

### 👩‍⚕️ Vet Profile  
View vet details, availability, and connect easily.  
<img src="pet_care_app/assets/screenshots/VetProfile.jpg" alt="Pet Profile" height="650"/>

### 👤 User Profile  
Edit your personal info and manage all your pets from one place.  
<img src="pet_care_app/assets/screenshots/UserProfile.jpg" alt="Pet Profile" height="650"/>

### 💬 Chatbot Assistant  
Get quick answers and guidance using the built-in AI chatbot.  
<img src="pet_care_app/assets/screenshots/chatbot.jpg" alt="Pet Profile" height="650"/>

### 📰 Pet Feed  
Stay updated with pet care tips and the latest pet-related news.  
<img src="pet_care_app/assets/screenshots/Feed.jpg" alt="Pet Profile" height="650"/>

### 🔍 Explore Other Pets & Vets  
Discover potential breeding matches and nearby veterinary services.  
<img src="pet_care_app/assets/screenshots/Explore.jpg" alt="Pet Profile" height="650"/>


---

## ✨ Contributing

Pull requests are welcome! If you’d like to help improve PetCare, feel free to fork the repo and submit a PR.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](pet_care_app/LICENSE) file for more info.

---

## 🙋‍♂️ Contact

Developed by Tarek Shawahni, Mays Khalaily, and Khalid Khalil.  
For questions or suggestions, feel free to open an issue.



