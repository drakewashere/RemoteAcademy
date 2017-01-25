class window.RemoteAcademy.Controllers.LabEditorController
  constructor: (lab, api, $routeParams, $timeout, $mdDialog)->
    @lab = lab
    @newLab = false

    if !lab? or !lab._id?
      @newLab = true
      @lab = {
        classes: []
        sections: []
      }

      # Set a due date a week in advance
      date = new Date()
      date.setHours(23); date.setMinutes(59); date.setSeconds(59); date.setMilliseconds(0);
      @lab.due = date.getTime() + 7 * 24 * 60 * 60 * 1000

      # Generate an ObjectID for this lab
      api.objectId().then (id)=> @lab._id = id


    # DATE PICKER ==========================================================================

    k1159 = 24 * 60 * 60 * 1000 - 1000
    @dayrange = (i for i in [0..31])
    @times = [
      {value: 0, name: "Midnight"}
      {value: 1 * 60 * 60 * 1000, name: "1am"}
      {value: 2 * 60 * 60 * 1000, name: "2am"}
      {value: 3 * 60 * 60 * 1000, name: "3am"}
      {value: 4 * 60 * 60 * 1000, name: "4am"}
      {value: 5 * 60 * 60 * 1000, name: "5am"}
      {value: 6 * 60 * 60 * 1000, name: "6am"}
      {value: 7 * 60 * 60 * 1000, name: "7am"}
      {value: 8 * 60 * 60 * 1000, name: "8am"}
      {value: 9 * 60 * 60 * 1000, name: "9am"}
      {value: 10 * 60 * 60 * 1000, name: "10am"}
      {value: 11 * 60 * 60 * 1000, name: "11am"}
      {value: 12 * 60 * 60 * 1000, name: "Noon"}
      {value: 13 * 60 * 60 * 1000, name: "1pm"}
      {value: 14 * 60 * 60 * 1000, name: "2pm"}
      {value: 15 * 60 * 60 * 1000, name: "3pm"}
      {value: 16 * 60 * 60 * 1000, name: "4pm"}
      {value: 17 * 60 * 60 * 1000, name: "5pm"}
      {value: 18 * 60 * 60 * 1000, name: "6pm"}
      {value: 19 * 60 * 60 * 1000, name: "7pm"}
      {value: 20 * 60 * 60 * 1000, name: "8pm"}
      {value: 21 * 60 * 60 * 1000, name: "9pm"}
      {value: 22 * 60 * 60 * 1000, name: "10pm"}
      {value: 23 * 60 * 60 * 1000, name: "11pm"}
      {value: k1159, name: "11:59pm"}
    ]

    # The functional guts of the date picker
    @updateTimestamp = ()=>
      date = new Date(@due.year, @due.month - 1, @due.day)
      @lab.due = date.getTime() + parseInt(@due.time)

    @updatePicker = (timestamp)=>
      date = new Date()
      date.setTime(timestamp)
      @due =
        time: ((date.getHours() * 60 + date.getMinutes()) * 60 + date.getSeconds()) * 1000
        day: date.getDate()
        month: date.getMonth() + 1
        year: date.getFullYear()

    @updatePicker(@lab.due)


    # SECTION EDITOR =======================================================================

    @sectionHeaderActions = [
      {label: "Add Section", icon: "add", execute: ()=>

        sectionNamePrompt = $mdDialog.prompt()
          .title('New Section Name')
          .placeholder('Introduction')
          .ariaLabel('Section Name')
          .ok('Create Section')
          .cancel('Cancel');

        $mdDialog.show(sectionNamePrompt).then (result)=>
          @lab.sections.push {
            name: result
            content: []
          }
      }
    ]

    @sectionActions = [
      {label: "Move Section Up", icon: "arrow_upward", execute: ($event, index)=>
        if index == 0 then return alert "Cannot move top section up"
        section = @lab.sections[index]
        @lab.sections.splice index, 1
        @lab.sections.splice index - 1, 0, section
      },
      {label: "Move Section Down", icon: "arrow_downward", execute: ($event, index)=>
        if index == @lab.sections.length - 1
          return alert "Cannot move bottom section down"
        section = @lab.sections[index]
        @lab.sections.splice index, 1
        @lab.sections.splice index + 1, 0, section
      },
      {label: "Delete Section", icon: "delete_sweep", execute: ($event, index)=>
        if confirm "Are you sure you want to delete this section?"
          @lab.sections.splice index, 1
      }
    ]


    # DATABASE INTERACTION =================================================================

    @saving = false

    @saveChanges = ()->
      @saving = true
      if @newLab
        api.insert("labs", @lab).then ()=>
          $timeout (()=>
            @saving = false
            @newLab = false
          ), 500
        , ()=>
          alert "Could not create lab! Check your internet connection and try again"
      else
        api.replace("labs", @lab).then ()=>
          $timeout (()=> @saving = false), 500
        , ()=>
          alert "Could not save lab! Check your internet connection and try again"

    @deleteLab = ()->
      if confirm "Are you sure you want to delete this lab?"
        api.delete("labs", @lab._id).then (d)=>
          if d.ok == 1
            window.location = "/admin/labs"
          else
            alert "Could not delete lab. Server returned an error!"


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.LabEditorController.$inject = [
  "lab", "raAPI", "$routeParams", "$timeout", "$mdDialog"
]
