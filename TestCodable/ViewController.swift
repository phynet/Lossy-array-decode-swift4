//
//  ViewController.swift
//  TestCodable
//
//  Created by Sofía Swidarowicz Andrade on 18/10/17.
//

import UIKit
//Trying out different approach to malformed json's payload
//https://stackoverflow.com/questions/46344963/swift-jsondecode-decoding-arrays-fails-if-single-element-decoding-fails/46713058#46713058
//We still can't receive a property with nil. Gives error.

class ViewController: UIViewController {
    
    struct GroceryProduct: Codable {
        var name: String
        var points: Int
        var description: String
        
        init(from decoder: Decoder) throws {
            
            // this is great when json data comes only with one of the properties declared in struct (name...)
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try values.decode(String.self, forKey: .name)
            self.points = try values.decodeIfPresent(Int.self, forKey: .points) ?? 0
            self.description = try values.decodeIfPresent(String.self, forKey: .description) ?? ""
        }
    }
    private struct DummyCodable: Codable {}
    
    let json = """
    [
        {
            "name": "Banana",
            "points": 200,
            "description": "A banana grown in Ecuador."
        },
        {
            "name": "Orange"
        },
       {}
    ]
    """.data(using: .utf8)!
    
    struct Groceries: Codable {
        var groceries: [GroceryProduct]
        
        init(from decoder: Decoder) throws {
            var groceries = [GroceryProduct]()
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                if let route = try? container.decode(GroceryProduct.self) {
                    groceries.append(route)
                    print("no trick")
                } 
                else {
                    //This si great to break the loop when there's no properties in the payload 
                    _ = try? container.decode(DummyCodable.self) // <-- TRICK
                    print("trick")
                }
            }
            self.groceries = groceries
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let jsonDecoder = JSONDecoder()
        do {
            let products = try jsonDecoder.decode(Groceries.self, from: json)
             print(products)
        }catch{
           print("error")
        }        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  

    
}








