# StackCalculator
Calculator for iOS, performs a calculation using the stack operations and operands

**Features:**
* Calculation in stack
* Different UI in different device orientations (Size classes feature)
* Build graphs
* Support iPhone, iPad
* Store history calculations

![alt tag](https://raw.github.com/dterekhov/stack-calculator-ios/master/Screenshots/Screenshot1.png)
![alt tag](https://raw.github.com/dterekhov/stack-calculator-ios/master/Screenshots/Screenshot2.png)

## Calculations
You can perform calculations by adding variables on the stack. To add to the stack, tap enter button ⏎ or any operation button (+, -, *, /).
For example to calculate 5 + 3
tap: 5 ⏎ 3 ⏎ +
or: 5 ⏎ 3 +

**Cancel operation**
Since the entire calculation is made on the stack, then you can perform a consistent elimination of all actions by tap Undo button.

## Graph
You can build graph directly by tap Build graph button. "M" (memory button) using as dependent X variable, i.e. for example y(M) = sin(M).
To build this graph enter: M ⏎ sin BuildGraphButton.

## History
Graph add to history by tap Build graph button. To remove the graph from history just swipe from right to left and tap Delete.

Project based on Stanford course ["Developing iOS 8 Apps with Swift"](https://itunes.apple.com/ru/course/developing-ios-8-apps-swift/id961180099) under the guidance of Professor Paul Hegarty