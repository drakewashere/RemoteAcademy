type MongoID = number;

interface FieldTableColumn {
  label: string;                        // Displays in the header of the column
  width: number | "auto";               // CSS width property for the column
  fromExp?: MongoID;                    // If pulling data from an experiment, this one
  input?: string;                       // Maybe associate with an experiment input field
  output?: string;                      // Maybe associate with an experiment output field
  editable?: boolean;                   // If true, users can edit values in this column
}


// NOTEBOOK FIELDS =========================================================================

type NotebookFieldType = "text" | "shortanswer" | "image" | "table";

interface NotebookField {
  type: NotebookFieldType;              // How to render this field in the UI
}

interface NotebookTextField extends NotebookField {
  type: "text";                         // Force type name
  content: string;                      // HTML-formatted contents of this section
}

interface NotebookImageField extends NotebookField {
  type: "image";                        // Force type name
  content: string;                      // Source link to image
}


interface NotebookInputType extends NotebookField {
  name: string;                         // Unique name used to store this field's value
}

interface NotebookShortAnswerType extends NotebookInputType {
  label: string;                        // Short text of the question the user is to answer
}

interface NotebookTableType extends NotebookInputType {
  label: string;                        // Title of the table
  editable: boolean;                    // When true, users can add and delete table rows
  columns: FieldTableColumn[];          // Array of table columns
}


// NOTEBOOK SECTIONS =======================================================================

interface NotebookSection {
  name: string;                         // Title of section
}

interface NotebookExperimentSection extends NotebookSection {
  experiment: MongoId;                  // Displays as a button to start this experiment
}

interface NotebookContentSection extends NotebookSection {
  content: NotebookField[];             // Ordered list of fields in this section
}


// MONGO ENTRY =============================================================================

interface Lab {
  classes: MongoID[];                   // Link this lab to specific classes
  title: string;                        // Human-readable lab name
  subtitle: string;                     // Slightly more information on the lab
  due: number;                          // Javascript timestamp of the due date
  experiments: MongoID[];               // Experiments in this lab (in order)
  sections: NotebookSection[];          // Lab notebook contents (grouped by section)
  _access: AccessControls;              // Security for this class
}
