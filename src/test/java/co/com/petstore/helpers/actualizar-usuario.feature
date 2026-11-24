@ignore
Feature: Precondición - actualizar un usuario

  Scenario: Actualizar usuario
    Given url baseUrl
    And path 'user', usuarioActualizado.username
    And request usuarioActualizado
    When method put
    Then status 200
