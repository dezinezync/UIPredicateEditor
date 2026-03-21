# UIPredicateEditor

**UIPredicateEditor** aims to be come a drop-in replacement of `NSPredicateEditor` for iOS, iPadOS and Mac Catalyst targets.

The plan is to have a 1:1 API implementation so implementing it in cross-platform projects and SwiftUI apps is seamless and requires to be setup only once.

**⚠️ WARNING**: This is a pre-release component, and as such should be used in production software with caution.

### TODO:
 
- [x] Missing implementations 
- [ ] Localizations 
- [ ] Test Suites      
- [x] Additional Documentation (where missing)
- [ ] Sample Project

### Examples

<details>
<summary>Manual Row Templates</summary>

```swift
import UIKit
import UIPredicateEditor

class ManualFilterViewController: UIViewController {
    
    var predicateEditor: UIPredicateEditorViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        predicateEditor = UIPredicateEditorViewController()
        
        var templates: [UIPredicateEditorRowTemplate] = []
        
        // 1. Add Compound Row for nesting
        templates.append(UIPredicateEditorRowTemplate(compoundTypes: [.and, .or, .not]))
        
        // 2. Add a template with a fixed set of choices (Pop-up style)
        templates.append(UIPredicateEditorRowTemplate(
            leftExpressions: [NSExpression(forKeyPath: "status")],
            rightExpressions: [
                NSExpression(forConstantValue: "Active"),
                NSExpression(forConstantValue: "Inactive"),
                NSExpression(forConstantValue: "Pending")
            ],
            modifier: .direct,
            operators: [.equalTo, .notEqualTo],
            options: []
        ))
        
        predicateEditor.rowTemplates = templates
        
        // Embed the editor
        addChild(predicateEditor)
        view.addSubview(predicateEditor.view)
        predicateEditor.view.frame = view.bounds
        predicateEditor.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        predicateEditor.didMove(toParent: self)
    }
}
```
</details>

<details>
<summary>Core Data Templates</summary>

```swift
import UIKit
import UIPredicateEditor
import CoreData

class MyFilterViewController: UIViewController {
    
    var predicateEditor: UIPredicateEditorViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Initialize the editor
        predicateEditor = UIPredicateEditorViewController()
        
        // 2. Configure Row Templates
        var templates: [UIPredicateEditorRowTemplate] = []
        
        // A. Add a Compound Row (Any/All/None) - Essential for nesting
        templates.append(UIPredicateEditorRowTemplate(compoundTypes: [.and, .or, .not]))
        
        // B. Use the Core Data helper to generate templates automatically
        if let entity = MyCoreDataStack.shared.persistentContainer.managedObjectModel.entitiesByName["Task"] {
            let coreDataTemplates = UIPredicateEditorRowTemplate.templates(
                withAttributeKeyPaths: ["title", "priority", "dueDate", "isCompleted"],
                in: entity
            )
            templates.append(contentsOf: coreDataTemplates)
        }
        
        // C. (Optional) Add a custom manual template
        let customTemplate = UIPredicateEditorRowTemplate(
            leftExpressions: [NSExpression(forKeyPath: "status")],
            rightExpressions: [
                NSExpression(forConstantValue: "Pending"),
                NSExpression(forConstantValue: "InProgress"),
                NSExpression(forConstantValue: "Completed")
            ],
            modifier: .direct,
            operators: [.equalTo, .notEqualTo],
            options: []
        )
        templates.append(customTemplate)
        
        predicateEditor.rowTemplates = templates
        
        // 3. Set initial predicate (optional)
        predicateEditor.predicate = NSPredicate(format: "title CONTAINS[cd] 'Gemini' AND priority > 2")
        
        // 4. Embed the editor view
        addChild(predicateEditor)
        view.addSubview(predicateEditor.view)
        predicateEditor.view.frame = view.bounds
        predicateEditor.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        predicateEditor.didMove(toParent: self)
        
        // 5. Listen for changes
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(predicateChanged), 
                                               name: .predicateDidChange, 
                                               object: nil)
    }
    
    @objc func predicateChanged(_ notification: Notification) {
        // Access the updated predicate directly
        let currentPredicate = predicateEditor.predicate
        print("Updated Predicate: \(currentPredicate.predicateFormat)")
    }
}
```

</details>

### Apps Using UIPredicateEditor

| | | |
|:-------------------------:|:-------------------------:|:-------------------------:|
|<a href="https://elytra.app"><img width="170" alt="Elytra" src="https://elytra.app/assets/images/home/appicon@2x.png"/></a>  | <a href="https://pockity.app"><img width="170" alt="Pockity" src="https://pockity.app/assets/images/home/appicon@2x.png"/></a> ||
| | | |

### License
MIT License, see the `LICENSE` file for more details. 

