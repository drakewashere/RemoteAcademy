type MongoID = number;

// MONGO ENTRY =============================================================================

interface Notebook {
  user: MongoID;                        // Reference to the User document
  lab: MongoID;                         // Reference to the Lab document
  completion: number;                   // % of questions answered, in range (0, 1)
  timestamps: number[];                 // Anti-cheating mechanism: every save point
  values: [{[row: string]: any}];       // Stored values, organized by section
}
