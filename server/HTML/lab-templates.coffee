module.exports =

  # MAIN PAGE TEMPLATE =====================================================================

  _page: """
    <div class="labcontainer" ng-style="{width: (lc.activeExperiment ? '980px' : '600px')}">
      <div class="inner">
        <article>
          <h1>{{lab.title}}: {{lab.subtitle}}</h1>
          {{{notebook}}}

          <!-- Submit button -->
          <section class="submit">
            <button class="homepagebutton submit" ng-click="lc.submitNotebook()">
              Submit Lab Notebook
            </button>
          </section>

        </article>
        <aside id="experimentContainer" ng-show="lc.activeExperiment"
               ng-include="lc.experiment[lc.activeExperiment].templateUrl">
        </aside>
        <ra-notebook-footer
          loading="lc.autosaveLoading"
          status="lc.autosaveStatus">
        </ra-notebook-footer>
      </div>
    </div>
  """

  _experiment: """
    <section class="experiment">
      <button class="homepagebutton"
        ng-bind="lc.experiment['{{section.experiment}}'].status || '{{section.name}}'"
        ng-class="{
          failed: lc.experiment['{{section.experiment}}'].failed || false,
          waiting: lc.experiment['{{section.experiment}}'].waiting || false,
          live: lc.experiment['{{section.experiment}}'].connected || false
        }"
        ng-click="lc.startExperiment('{{section.experiment}}')">
      </button>
    </section>
  """

  _section: """
    <section ra-autosave-section="{{index}}">
      <h2>{{section.name}}</h2>
      <div class="box">{{{inner}}}</div>
    </section>
  """


  # PAGE COMPONENT TEMPLATES ===============================================================

  text: "<div class='textbit'>{{{content}}}</div>"

  image: "<img src='{{content}}' style='max-width: 300px'>"

  shortanswer: """
    <form>
      <label for="{{name}}">{{label}}</label>
      <textarea class="shortanswer" name="{{name}}"
        ra-autosave="lc.saveSection(section, '{{name}}', value)"
      />{{value}}</textarea>
    </form>
  """

  experiment: """
    <button class="experiment" ng-click="startExperiment('{{name}}')">{{label}}</button>
  """

  table: """
    <form>
      <label for="{{name}}">{{label}}</label>
      <ra-data-table name="{{name}}"
                     columns='{{{json columns}}}' data='{{{json value}}}'
                     change="lc.saveSection(section, '{{name}}', value)">
      </ra-data-table>
    </form>
  """
