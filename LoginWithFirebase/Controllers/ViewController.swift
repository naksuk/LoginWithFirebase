import UIKit
import Firebase
import PKHUD

class ViewController: UIViewController {

    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBAction func haveAccount(_ sender: Any) {
        pushToLoginViewController()
    }
    
    @IBAction func tappedRegister(_ sender: Any) {
        handleAuthToFirebase()
        print("認証中")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNotificationObserver()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
    }
    
    private func pushToLoginViewController() {
        let storyBoard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyBoard.instantiateViewController(identifier: "LoginViewController" ) as! LoginViewController
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    private func setupViews() {
        registerButton.backgroundColor = UIColor.rgb(red: 255, green: 221, blue: 187)
        registerButton.isEnabled = false
        registerButton.layer.cornerRadius = 10
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name:UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func handleAuthToFirebase() {
        HUD.show(.progress, onView: view)
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("認証情報の保存に失敗しました。\(err)")
                HUD.hide{ (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            self.addUserInfoFirestore(email: email)
        }
    }
    
    //Firestoreにユーザ情報を保存
    private func addUserInfoFirestore(email: String) {
        guard let uid  = Auth.auth().currentUser?.uid else { return }
        guard let name = self.usernameTextField.text else { return }
        
        let docData = ["email": email, "name": name, "createdAt": Timestamp()] as [String : Any]
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        userRef.setData(docData) { (err) in
            if let err = err {
                print("Firestoreへの保存に失敗しました。\(err)")
                HUD.hide{ (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            self.fetchUserInfoFromFirestore(userRef: userRef)
        }
    }
    
    //Firestoreからユーザ情報を取得
    private func fetchUserInfoFromFirestore(userRef: DocumentReference) {
        userRef.getDocument { (snapshot, err) in
            if let err = err {
                print("ユーザーの取得に失敗しました。")
                HUD.hide{ (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            
            guard let data = snapshot?.data() else { return }
            let user = User.init(dic: data)
            print("ユーザー情報の取得ができました。\(user.name)")
            HUD.hide{ (_) in
                //HUD.flash(.success, delay: 1)
                HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                    self.presentToHomeViewController(user: user)
                }
            }
        }
    }
    
    private func presentToHomeViewController(user: User) {
        let storyBoard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = storyBoard.instantiateViewController(identifier: "HomeViewController" ) as! HomeViewController
        homeViewController.user = user
        homeViewController.modalPresentationStyle = .fullScreen
        self.present(homeViewController, animated: true, completion: nil)
    }
    

    
    @objc func showKeyboard(notification: Notification) {
        print("Keyboard is showing")
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        let registerButtonMaxY = registerButton.frame.maxY
        let distance = registerButtonMaxY - keyboardMinY + 20
        
        let transform = CGAffineTransform(translationX: 0, y: -distance)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = transform
        })
    }
    
    @objc func hideKeyboard() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = .identity
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? true
        
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 221, blue: 187)
            
        } else {
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 141, blue: 0)
        }
    }
}
