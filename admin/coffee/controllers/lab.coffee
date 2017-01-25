class window.RemoteAcademy.Controllers.LabListController
  constructor: (list, api, $location)->
    @data = list

    @columns = [
      {label: "Title", key: "title"},
      {label: "Subtitle", key: "subtitle"},
      {label: "Due", key: "due", map: (t)-> new Date(t).toLocaleString()},
      {label: "Classes", key: "classes", map: (t)-> t.length},
    ]

    @actions = [
      {
        label: "Delete",
        icon: "delete forever",
        execute: (id)=> @delete(id),
        confirm: true
      },
      {
        label: "Duplicate",
        icon: "content_copy",
        execute: (id)=> @duplicate(id),
        confirm: true
      },
      {
        label: "Edit",
        icon: "edit",
        execute: (id)=> @edit(id)
      }
    ]

    @newLab = ()-> $location.url('/admin/labs/new')


    # DATA ACTIONS =========================================================================

    @reload = ()-> api.listLabs().then (labs)=> @data = labs

    @delete = (id)->
      api.delete("labs", id).then (d)=>
        if d.ok == 1
          for index, row of @data when row._id == id
            @data.splice(index, 1)
        else
          alert "Could not delete row. Server returned an error!"

    @duplicate = (id)->
      # Get the input object
      obj = (row for row in @data when row._id == id)[0]
      if !obj? then return alert "Could not find entry to duplicate"

      # Duplicate it without its id
      newObj = angular.copy(obj)
      newObj.title = newObj.title + " (copy)"
      delete newObj._id

      # Add the duplicate to the database
      api.insert("labs", newObj).then (d)=>
        if d.ok == 1
          @reload()
        else
          alert "Could not duplicate row. Server returned an error!"

    @edit = (id)->
      $location.url("/admin/labs/edit/#{id}")


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.LabListController.$inject = [
  "list", "raAPI", "$location"
]
