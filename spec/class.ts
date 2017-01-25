
// ADMIN INTERFACE SECURITY ================================================================

interface AccessControls {
  users: string[];                      // Names of users authorized to edit this class
  groups: string[];                     // User groups authorized to edit this class
}


// MONGO ENTRY =============================================================================

interface ClassSection {
  id: number | string;                  // Section ID using the school's numbering system
  name: string;                         // Human readable name, eg "Section 1"
  timeslot: string;                     // Human readable time, eg "Mondays at 9am"
}

interface Class {
  name: string;                         // Human-readable class name
  professor: string;                    // Full name of professor (formatted however)
  school: string;                       // Full name of school where the class is located
  domains: string[];                    // Users with one of these email domain can register
  sections: ClassSection[];             // Sections of this class
  _access: AccessControls;              // Security for this class
}
