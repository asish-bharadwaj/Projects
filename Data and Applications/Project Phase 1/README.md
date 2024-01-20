Project Phase 1 Description:

The Task:
Consider a mini-world of your choice and come up with the data requirements for the database design and functional requirements for database operations.

A mini-world is a set of users and how they will use the database you design—for example, a school examination system used by students, teachers, and more.
Note: You cannot use any of the mini-worlds provided in the group assignments.
Note: State your assumptions and constraints of your mini-world, especially if it's a hypothetical or unknown mini-world.

Database Requirements:
Please list out the requirements of your database/mini-world

Your mini-world should result in data requirements that have:
● At least five strong entity types

● At least one weak entity with two key attributes

● At least two weak-entity types

● At least five relationship types(which should include cardinality ratios and participation constraints)

● At least one (n > 2) degree relationship type.

● Few composite, multi-valued, derived attributes

● Relationship type with the same participating entity type in distinct roles
  Example: In a COMPANY database SUPERVISION relationships between EMPLOYEE (in the role of supervisor) and EMPLOYEE (in the role of subordinate)
  
● At least one (n > 3) degree relationship type

Functional Requirements
In your mini-world, you will be required to have applications that operate on the database. Any operation on your database for some useful purpose in your mini-world is a functional
requirement.
For instance, let's consider a scenario where you're managing employee records.
These operations are functional requirements:

Retrieval Operations (at least one query for each)
○ Selection: "Retrieve a list of all employees who joined the company in the last year."
○ Projection: Query to enable the users to search the database by a particular attribute. Example: "Names of all employees in the marketing department."
○ Aggregate (SUM, MAX, MIN, AVG): Perform an operation on the data to get the desired output. Example: "The highest monthly sales achieved by any employee."
○ Search: Search (partial text match) for entries in an entity, matching for subparts of the entries. Example: Searching for "Man" to find "Manager."
● Analysis (at least two analysis reports to be generated)
Note: We expect that these reports convey something about the relationship between
entities and are not simple selection operations from a single entity. To do so, you have to
use the Join operator.
Examples:
"Average tenure of employees in each department."
"Success rate of projects undertaken by dierent departments.”
● Modification Operations (at least one query for each)
○ Insertion of data, check for violations of integrity constraints. “Adding the details
of an employee when he joins”
○ Update operation. “Update the salary of an employee after promotion”
○ Delete operation. “Delete the details of the employee after he leaves the company”


