var app = angular.module('ProblemFormApp', ['ui.sortable', 'ProblemsHelper']);

app.controller('ProblemFormController', ['$scope', '$http', '$window', 'ProblemDefaultSetter', 'TaskJSONInputParser', function($scope, $http, $window, ProblemDefaultSetter, TaskJSONInputParser) {
    // Default values for a new problem
    $scope.problem = ProblemDefaultSetter({});

    $scope.saveProblem = function($event) {
        $event.preventDefault();

        if (!$scope.problem.permalink_attributes.url || $scope.problem.permalink_attributes.url.trim().length == 0) {
            $scope.problem.permalink_attributes["_destroy"] = true;
        }

        // Stringify JSON
        angular.forEach($scope.problem.tasks_attributes, function(task, index) {
            if (task.json) {
                var newArr = [];
                angular.forEach(task.input_fields, function(field) {
                    if (field.label && field.label.length) {
                        this.push(field);
                    }
                }, newArr);
                task.input = angular.toJson(newArr, true);
            }

            task.order = index;
        });

        startSpinner();
        if ($scope.problem.id !== undefined && $scope.problem.id !== null) {
            var endPoint = "/problems/" + $scope.problem.id + ".json";
            var savePromise = $http.put(endPoint, $scope.getSubmissionParams());
        } else {
            var endPoint = "/problems.json";
            var savePromise = $http.post(endPoint, $scope.getSubmissionParams());
        }

        savePromise.success(function(data) {
            $scope.problem = ProblemDefaultSetter(data);
            TaskJSONInputParser($scope.problem.tasks_attributes);

            if (!data.errors || data.errors.length == 0) {
                $window.location.pathname = "/problems/" + data.id;
            }
        }).finally(function() {
            stopSpinner();
        });
    };

    $scope.getSubmissionParams = function() {
        return {
            authenticity_token: $scope.authenticity_token,
            problem: $scope.problem
        };
    };

    $scope.addTask = function() {
        $scope.problem.tasks_attributes.push({});
    };

    $scope.removeTask = function(index) {
        $scope.problem.tasks_attributes.splice(index, 1);
    };

    $scope.taskAddInputField = function(index) {
        if (!$scope.problem.tasks_attributes[index].input_fields) {
            $scope.problem.tasks_attributes[index].input_fields = [];
        }
        $scope.problem.tasks_attributes[index].input_fields.push({});
    };
}]);

app.directive('authenticityToken', function() {
    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            scope["authenticity_token"] = attrs['authenticityToken'];
        }
    };
});
