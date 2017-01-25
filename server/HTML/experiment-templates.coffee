module.exports =

  # MAIN PAGE TEMPLATE =====================================================================

  _experiment: """
    <div class="experiment">
      <section>
        <h2>Livestream</h2>
        <div class="box experiment stream">
          <img class="live" id="frame-{{experiment._id}}">
        </div>
        </img>
      </section>
      <section>
        <h2>Inputs</h2>
        <div class="box experiment">
          {{{input}}}
        </div>
      </section>
      <!--
      <section>
        <h2>Data Collection</h2>
        <div class="box experiment">

          <div data-input ng-show="">
            <label>Collection Rate (Hz)</label>
            <input type="range" value="1"
                min=""
                max="" step="1"
                ng-model="lc.collectionRate">
            <span ng-bind="lc.collectionRate"></span>
          </div>

          <div data-input ng-show="">
            <label>Collection Rate (Hz)</label>
            <input type="range" value="1"
                min=""
                max="" step="1"
                ng-model="lc.collectionTime">
            <span ng-bind="lc.collectionTime"></span>
          </div>

        </div>
      </section>
      -->
      <section class="experiment">
        {{#ifCond experiment.output.type 'stream'}}
        <button class="homepagebutton"
          ng-click="lc.toggleStreaming('{{experiment._id}}')"
          ng-bind="(lc.collecting ? 'Stop' : 'Start') + ' Collecting Data'">
        </button>
        {{else}}
        <button class="homepagebutton"
          ng-click="lc.triggerCollection('{{experiment._id}}',{{experiment.output.time}})"
          ng-disabled="lc.collecting"
          ng-bind="(lc.collecting ? 'Collecting...' : 'Collect Data')">
        </button>
        {{/ifCond}}
      </section>
    </div>
  """

  _input: """
    <div data-input="{{object.id}}">
      <label>{{object.label}}</label>
      {{{inner}}}
    </div>
  """

  _output: """
    <div data-output>{{{inner}}}</div>
  """


  # PAGE COMPONENT TEMPLATES ===============================================================

  number: "<p>{{value}}</p>"

  toggle: """
    <button class="toggle"
            toggle-button="lc.updateInput('{{device}}', '{{id}}', state)">
      Off
    </button>
  """

  range: """
    <input type="range" value="0" min="{{min}}" max="{{max}}" step="{{step}}"
      ng-model-options="{debounce: 500}"
      ng-model="state"
      ng-change="lc.updateInput('{{device}}','{{id}}', state)">
    <span ng-bind="state"></span>
  """
