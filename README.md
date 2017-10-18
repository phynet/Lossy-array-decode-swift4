
# "Lossy" Array Decodes in Swift 4

# Situation

So, imagine that we have the next JSON payload which give us an array of groceries items:

```json
    [
        "groceries": {
            "name": "Banana",
            "points": 200,
            "description": "A banana grown in Ecuador."
        }
    ]
```

Great, we started by creating our properties structure:
        
 ```swift
        struct GroceryProduct: Codable {
              var name: String
              var points: Int
              var description: String

        }
```

But, we stop here, thinking: Should I use optionals for the properties?, this properties `could be nil` for some backend reason? :p we don't know...so, we ask the backend designer which response is: "they won't ever be nil"...those fields are non-optional then.

So we do something like:

```swift
    struct Groceries: Codable {
        var groceries: [GroceryProduct]
        
        init(from decoder: Decoder) throws {
            var groceries = [GroceryProduct]()
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                if let route = try? container.decode(GroceryProduct.self) {
                    groceries.append(route)
                } 
            }
            self.groceries = groceries
        }
    }
    
    func startSerializing(){
      let jsonDecoder = JSONDecoder()
        do {
            let products = try jsonDecoder.decode(Groceries.self, from: json)
             print(products)
        }catch{
           print("error in json")
        }        
    }
```

And it works, until...we have this JSON payload response:     

```json
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
```

We're missing `points` and `description` fields and our loop is in an infinite state. >.<  fire. Why is this happening?

The reason is due to how `UnkeyedDecodingContainer.currentIndex` works. CurrentIndex is not incremented unless a decode succeed, in this case decode is not succeding because there are missing fields which are NON-OPTIONALS. Lossy array decodes just doesn't work.  Great.

## Solution

I found out here: https://bugs.swift.org/browse/SR-5953 that we can create an empty `Dummy struct` in order to avoid this infinite loop:

```swift

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
                    _ = try? container.decode(DummyCodable.self) // <-- TRICK
                    print("trick")
                }
            }
            self.groceries = groceries
        }
    }
```

We get: `Groceries(groceries: [TestCodable.ViewController.GroceryProduct(name: "Banana", points: 200, description: "A banana grown in Ecuador.")])`
 
    
Ok, this help us to avoid an infinite loop, but what if we want to store the value that comes in the payload anyway?. We can create an init block indicating default values when a `key is missing`. 


```swift
    struct GroceryProduct: Codable {
            var name: String
            var points: Int
            var description: String

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try values.decode(String.self, forKey: .name)
                self.points = try values.decodeIfPresent(Int.self, forKey: .points) ?? 0
                self.description = try values.decodeIfPresent(String.self, forKey: .description) ?? ""
            }
        }
 ```
 
With this implementation now we have this result:

`Groceries(groceries: [TestCodable.ViewController.GroceryProduct(name: "Banana", points: 200, description: "A banana grown in Ecuador."), 
TestCodable.ViewController.GroceryProduct(name: "Orange", points: 0, description: "")])`


You can find a question of this behavior in :
https://stackoverflow.com/questions/46344963/swift-jsondecode-decoding-arrays-fails-if-single-element-decoding-fails/46713058#46713058 

A solution in: https://bugs.swift.org/browse/SR-5953

I mixed solutions in order to have this working. Thank you to all swifty brains out there ;) 

I have to acknowledge @j4n0 also, who knows were to search when you get stuck in swift. :D
