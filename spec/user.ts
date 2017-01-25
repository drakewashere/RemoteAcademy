type MongoID = number;

interface NotificationSettings {
  lab: boolean;                         // Receive notifications about new labs
}

type Registration = [MongoID, number];  // ID of class document and then section number

interface User {
  username: string;                     // First part of school email address (eg. smithj)
  domain: string;                       // Second part of school email address (eg. rpi.edu)
  email: string;                        // Preferred contact email (not necessarily school)
  fullname?: string;                    // Person's full name, provided by them

  notifications: NotificationSettings;  // Contact event & frequency settings
  classes: Registration[];              // Classes the user is enrolled in

  admin?: boolean;                      // True if the user can access the admin interface
  adminGroups?: string[];               // Access groups for the admin interface
}
