type MongoID = number;

// ADMIN INTERFACE SECURITY ================================================================

interface AccessControls {
  users: string[];                      // Names of users authorized to edit this class
  groups: string[];                     // User groups authorized to edit this class
}


// INPUTS ==================================================================================

type LabInputType = "trigger" | "toggle" | "range" | "string";

interface LabInput {
  id: string;                           // Unique (short) string used to identify this input
  label: string;                        // Shown in the user interface
  type: LabInputType;                   // Determines how to render the UI component
  default: any;                         // Default value
  map: string;                          // JS-evaluable function (x)-> formatted x
  visible?: boolean;                    // When false, the value will just stay default
}

interface LabRangeInput extends LabInput {
  type: "range";                        // Force the type name
  default: number;                      // Force the type signature
  max: number;                          // Maximum value
  min: number;                          // Minimum value
  step?: number;                        // Step size (granularity)
}

interface LabStringInput extends LabInput {
  type: "string";                       // Force the type name
  default: string;                      // Force the type signature
  validate: string;                     // JS-evaluable function (x)-> boolean
}

interface LabToggleInput extends LabInput {
  type: "toggle";                       // Force the type name
  default: boolean;                     // Force the type signature
}

interface LabGPIOInput extends LabToggleInput {
  pin: number;                          // GPIO Pin Number (integer)
}


type LabHatInputTypes = LabHatDCInput | LabHatStepperInput;

interface LabHatDCInput extends LabRangeInput {
  motor: 0 | 1 | 2 | 3;                 // Which motor port this is hooked to
}

interface LabHatStepperInput extends LabRangeInput {
  motor: 0 | 1;                         // Which motor port this is hooked to
  mode: "speed" | "angle";              // Which aspect of the motor is being controlled
}


// OUTPUTS =================================================================================

type SamplingRate = number | [number, number] | "fastest" | "poll" ;

type SamplingLength = number | [number, number];

interface OutputSampling {
  type: "collect" | "stream";           // In collect mode, the server holds data samples
                                        // In stream mode, they get forwarded to the client
  time: SamplingLength;                 // How long to record data at a time, in ms
                                        // When this is a range the client shows a slider
  rate?: SamplingRate = "fastest";      // Desired frequency of data records
                                        // When this is a range the client shows a slider
}


interface LabOutput {
  id: string;                           // Unique (short) string used to identify this input
  label: string;                        // Shown in the user interface
  map?: string;                          // JS-evaluable function (x)-> formatted x
}

interface LabGPIOOutput extends LabOutput {
  pin: number;                          // GPIO Pin Number (integer)
  float: "high" | "low" | "none";       // Controls the RPi's pulldown resistors
}

interface LabProOutput extends LabOutput {
  interface: "analog" | "digital";      // What type of sensor is this
  sensor: string;                       // Name of sensor (might be necessary sometimes)?
  port: number;                         // Analog or digital plug number
}


// DEVICES =================================================================================

type LabDeviceType = "gpio" | "serial" | "labpro" | "motorhat" ;

interface LabDevice {
  type: LabDeviceType;                  // Currently supported device types
  inputs: LabInput[];                   // User input properties controlled by this device
  outputs: LabOutput[];                 // Properties of the lab measured by this device
}

interface LabProDevice extends LabDevice {
  type: "labpro";                       // Force the type name
  inputs: undefined;                    // Currently (and hopefully always) unsupported
  output: LabProOutput[];               // Outputs that link to specific LabPro sensors
}

interface LabGPIODevice extends LabDevice {
  type: "gpio";                         // Force the type name
  inputs: LabGPIOInput[];               // GPIO supports only boolean and needs pin numbers
  output: LabGPIOOutput[];              // Boolean w/ pin numbers and pulldown state
}

interface LabHatDevice extends LabDevice {
  type: "motorhat";                     // Force the type name
  inputs: LabHatInputTypes[];           // Inputs for stepper and DC motors
  output: undefined;                    // The motor hat cannot read anything
}


// MONGO ENTRY =============================================================================

interface Experiment {
  name: string;                         // Human-readable experiment name
  timeout: number;                      // Integer number of seconds before cutting off user
  output: OutputSampling;               // Controls how data is returned
  rales: string[];                      // Array of LabBox ID's assigned to this experiment
  setup: {[name: string]: LabDevice};   // Array of input and output devices
  _access: AccessControls;              // Who can edit this experiment
}
