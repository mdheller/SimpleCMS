app = angular.module('ProblemPage', ['ProblemsHelper', 'ui.ace', 'Directives', 'SimpleCMS.jsrepl', 'SimpleCMS.InteractiveTerminal', 'ProblemId', 'AuthenticityToken'])

app.controller('ProblemPage', ['$scope', '$http', '$window', '$timeout', 'jsrepl', 'ProblemsHelper', 'ProblemId', 'AuthenticityToken', ($scope, $http, $window, $timeout, jsrepl, ProblemsHelper, ProblemId, AuthenticityToken) ->

  $scope.alerts = []
  Object.defineProperty $scope.alerts, "add",
    value: (type, message) ->
      if message
        this.push
          type: type
          message: message

  $scope.problem = ProblemsHelper.get id: ProblemId, ->
    if $scope.problem.user_code
      $scope.code = $scope.problem.user_code.code ||= ""
    else
      $scope.code = $scope.problem.stub
  , ->
    $scope.alerts.add("danger", "Something went wrong. Please try again later.")

  # Set height = window height, subtract nav and footer heights
  $scope.style =
    height: $window.innerHeight - 72 - 60

  $scope.isNumber = (input) ->
    not isNaN(Number(input))

  updateCodeTimeout = null
  $scope.$watch 'code', ->
    $timeout.cancel(updateCodeTimeout) if updateCodeTimeout isnt null
    updateCodeTimeout = $timeout ->
      $scope.savingCode = true
      $http.post '/codes.json',
        authenticity_token: AuthenticityToken
        code:
          problem_id: $scope.problem.id
          code:       $scope.code
      .finally ->
        $scope.savingCode = false
    , 2500

  $scope.aceLoad = (editor) ->
    editor.commands.addCommand
      name: 'run',
      bindKey:
        win: 'Ctrl-B'
        mac: 'Command-B'
      exec: -> $scope.runCode()

    editor.getSession().setTabSize(2)
    editor.getSession().setUseSoftTabs(true)
    editor.getSession().setUseWrapMode(true)

  $scope.submitAll = ->
    submissions = []
    angular.forEach $scope.problem.tasks_attributes, (task) ->
      return if task.solved
      return unless task.submission_allowed

      task.submission ||= {}

      submissions.push
        task_id: task.id
        input: task.submission.input
        code: task.submission.code

    startSpinner()

    $http.post("/submissions.json", {authenticity_token: AuthenticityToken, submissions: submissions})
         .success (submissions) ->
           for submission in submissions
            index = parseInt(i for i, task of $scope.problem.tasks_attributes when task.id is submission.task_id)

            if submission.accepted
              $scope.alerts.add("success", "Test case #{index + 1} accepted.")
            else
              $scope.alerts.add("danger", "Test case #{index + 1} failed.")

           $scope.problem = ProblemsHelper.get(id: $scope.problem.id)
         .error ->
           $scope.alerts.add("danger", "Cannot submit your answers. Please refresh the page and try again.")
         .finally ->
           stopSpinner()

  $scope.runCode = (code = $scope.code, listeners = {}) ->
    originalBefore = listeners["before"]
    listeners["before"] = ->
      jsrepl.writer(">\nRunning...\n", "jqconsole-old-prompt")
      originalBefore() if originalBefore?

    jsrepl.eval(code, listeners)

  $scope.runCodeWithTestCases = ->
    whitelist = (index for index in arguments)

    angular.forEach $scope.problem.tasks_attributes, (task, index) ->
      return if task.json
      return if whitelist.length && whitelist.indexOf(index) < 0

      # TODO We should probably check that task.input itself is a valid Python
      # program before continuing, else, it is likely that the user will see
      # some weird shit error message

      task.submission = {} unless task.submission
      task.submission.input = "" unless task.submission.input
      task.submission.code  = """
                              ### Beginning of injected code
                              #{task.input}
                              ### End of injected code

                              #{$scope.code}
                              """

      stdout = ""

      jsrepl.eval task.input,
        before: ->
          jsrepl.writer(">\n", "jqconsole-old-prompt")
          jsrepl.writer("Test Case #{index + 1}\n", "jqconsole-system")
          jsrepl.writer("Already solved, hence skipping this test case.\n", "jqconsole-system") if task.solved

      return if task.solved

      jsrepl.eval $scope.code,
        output: (data) -> stdout += data
        after: ->
          $scope.$apply ->
            task.submission.input = stdout
])
