###
The MIT License (MIT)

Copyright (c) 2015 Joseph Wynn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

angular.module('relativeDate', [])
  .value('now', null)
  .value('relativeDateTranslations', {
    just_now: 'just now'
    seconds_ago: '{{time}} seconds ago'
    a_minute_ago: 'a minute ago'
    minutes_ago: '{{time}} minutes ago'
    an_hour_ago: 'an hour ago'
    hours_ago: '{{time}} hours ago'
    a_day_ago: 'yesterday'
    days_ago: '{{time}} days ago'
    a_week_ago: 'a week ago'
    weeks_ago: '{{time}} weeks ago'
    a_month_ago: 'a month ago'
    months_ago: '{{time}} months ago'
    a_year_ago: 'a year ago'
    years_ago: '{{time}} years ago'
    over_a_year_ago: 'over a year ago'
    seconds_from_now: 'in {{time}} seconds'
    a_minute_from_now: 'in 1 minute'
    minutes_from_now: 'in {{time}} minutes'
    an_hour_from_now: 'in an hour'
    hours_from_now: 'in {{time}} hours'
    a_day_from_now: 'tomorrow'
    days_from_now: 'in {{time}} days'
    a_week_from_now: 'in a week'
    weeks_from_now: 'in {{time}} weeks'
    a_month_from_now: 'in a month'
    months_from_now: 'in {{time}} months'
    a_year_from_now: 'in a year'
    years_from_now: 'in {{time}} years'
    over_a_year_from_now: 'in over a year'
  })
  .filter 'relativeDate', ['$injector', 'now', 'relativeDateTranslations', ($injector, _now, relativeDateTranslations) ->
    if $injector.has('$translate')
      # Use angular-translate (or any service which implements .instant(id, params)) if it's available
      $translate = $injector.get('$translate')
    else
      # Simple polyfill for the angular-translate service
      $translate = {
        instant: (id, params) ->
          relativeDateTranslations[id].replace('{{time}}', params.time)
      }

    calculateDelta = (now, date) ->
      Math.round(Math.abs(now - date) / 1000)

    (date) ->
      now = if _now then _now else new Date()
      date = new Date(date) unless date instanceof Date
      delta = null

      minute = 60
      hour = minute * 60
      day = hour * 24
      week = day * 7
      month = day * 30
      year = day * 365

      delta = calculateDelta(now, date)

      if delta > day && delta < week
        # We're dealing with days now, so time becomes irrelevant
        date = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0)
        delta = calculateDelta(now, date)

      translate = (translatePhrase, timeValue) ->
        if translatePhrase == 'just_now'
          translateKey = translatePhrase
        else if now >= date
          translateKey = "#{translatePhrase}_ago"
        else
          translateKey = "#{translatePhrase}_from_now"

        $translate.instant(translateKey, { time: timeValue })

      switch
        when delta < 30 then translate('just_now')
        when delta < minute then translate('seconds', delta)
        when delta < 2 * minute then translate('a_minute')
        when delta < hour then translate('minutes', Math.floor(delta / minute))
        when Math.floor(delta / hour) == 1 then translate('an_hour')
        when delta < day then translate('hours', Math.floor(delta / hour))
        when delta < day * 2 then translate('a_day')
        when delta < week then translate('days', Math.floor(delta / day))
        when Math.floor(delta / week) == 1 then translate('a_week')
        when delta < month then translate('weeks', Math.floor(delta / week))
        when Math.floor(delta / month) == 1 then translate('a_month')
        when delta < year then translate('months', Math.floor(delta / month))
        when Math.floor(delta / year) == 1 then translate('a_year')
        else translate('over_a_year')
  ]
