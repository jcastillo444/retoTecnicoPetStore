@ignore
Feature: Precondición - crear un usuario

  Scenario: Crear usuario
    Given url baseUrl
    And path 'user'
    And request usuario
    When method post
    Then status 200
