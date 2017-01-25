// LABBOX TO SERVER ========================================================================

interface DataEntry {
  time: number;                             // Javascript timestamp
  data: {[key: string]: string}[];          // Keys and values at this time
}

interface LabBoxEntry {
  index: number;                            // Ensures the entries are considered in order
  data: {[deviceID: string]: DataEntry[]};  // Javascript timestamp
}


// INTERFACE TO LABBOX =====================================================================

interface ControlCommand {
  device: string;                           // Device Identifier (from the Experiment)
  key: string;                              // Input Identifier (from the Experiment)
  value: any;                               // New input value, or 1 for triggers
}
