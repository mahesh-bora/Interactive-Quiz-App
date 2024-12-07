# Interactive Quiz App 🧠 - [Stimuler Assignment]

An interactive mobile application designed to help users explore and learn about different map types through engaging quizzes. Built with Flutter and following Clean Architecture principles, this app provides an educational and enjoyable learning experience.

## 🧑🏻‍💻 Features

- Interactive map type quizzes
- Real-time data from Firebase
- Progress tracking across levels
- Clean, modular architecture
- Efficient state management

## 👨‍💻: App Screenshots

| Map Screen | Choose Exercise Screen | Quiz Screen | 
| :---         |     :---      |     :---      |       
| <img src="https://github.com/user-attachments/assets/90cb1424-c963-4f07-b70e-e4d8c288675b" width="260" height="auto" />  | <img src="https://github.com/user-attachments/assets/10508552-3093-414b-8d58-88b230ecb57c" width="250" height="auto" /> | <img src="https://github.com/user-attachments/assets/d9ab2a3b-ca44-4d75-96d4-ce67f8732c73" width="250" height="auto" />     

| Option Selection Screen | Correct Answer Screen | Correct Answer BottomSheet |
| :---         |     :---      |      :---      |
 <img src="https://github.com/user-attachments/assets/a1c2cffa-9983-4eae-a38b-525db0bfcbf1" width="250" height="auto" />    | <img src="https://github.com/user-attachments/assets/eb7c36e3-3e0e-4eb6-8617-de4c287e0101" width="250" height="auto" /> | <img src="https://github.com/user-attachments/assets/f89f10ee-3046-4d4a-aacb-aaa919a03050" width="250" height="auto" /> 

| Incorrect Answer Scren | Inorrect Answer BottomSheet |  Loading Screen |
| :---         |     :---      |      :---      |
 <img src="https://github.com/user-attachments/assets/1abf768c-a6d6-4c3d-ab15-6ca53acfbdba" width="250" height="auto" />    | <img src="https://github.com/user-attachments/assets/c3377a0a-273d-41a8-9640-308a8585e7bc" width="250" height="auto" /> | <img src="https://github.com/user-attachments/assets/c0b237e5-b34c-43b1-a65f-e5f3f45e5d57" width="250" height="auto" /> 

  | Congratulations Screen | Updated Map Screen | Updated Attempted Exercises Screen |
| :---         |     :---      |      :---      |
 <img src="https://github.com/user-attachments/assets/b525d697-9993-4d5e-97e4-0a4f02f8588c" width="250" height="auto" />    | <img src="https://github.com/user-attachments/assets/fbb2971a-8677-4766-a076-ccf1be2da5d0" width="250" height="auto" /> | <img src="https://github.com/user-attachments/assets/263120b2-79b5-44a5-a49a-b493cc90aa06" width="250" height="auto" /> 

</div>

## 🔗 App Demonstration 

You can view a demo here : https://drive.google.com/file/d/1YqTTp_7c2nUImOvNvZzMSKOw8iwtodS3/view?usp=sharing

## 💻Installation

* Clone the Repository and Change the directory.

```bash
  flutter pub get
  flutter run
```
    
## 🧑🏻‍💻Run 

Clone the repository and change directory.

```bash
  git clone https://github.com/mahesh-bora/Stimuler-Assignment.git
```

Go to the project directory

```bash
  cd stimuler_assignment
```

Flutter pub get and run
```bash
  flutter pub get
  flutter run
```

## 📃Database Design
![image](https://github.com/user-attachments/assets/2bb0214d-4cab-4046-af1f-ecab84c5822b)

  ![image](https://github.com/user-attachments/assets/a0e9240c-a82d-45ae-ab5b-91e55f8335a5)
  ![image](https://github.com/user-attachments/assets/cfc02ddb-df1b-45ff-ac29-418c1ed5a966)

## 💭Assumptions made for smoother implementation
- Every Level has only two exercises
- If an individual has attempted a quiz once, then they can't attempt it again
- The green path is filled only after the level is unlocked and filled from current unlocked level to the latest unlocked level 

## 🚧 Known Limitations

- Limited offline functionality
- Requires internet connection
- Fixed map type quiz set
- Potential performance constraints with large datasets

### Flutter Version - 3.24.3
## 🖊️Author

- [Mahesh Bora](https://www.github.com/mahesh-bora) - (boraamahesh@gmail.com)
