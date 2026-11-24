@ignore
Feature: Limpieza - eliminar un usuario si existe

  Scenario: Eliminar usuario
    Given url baseUrl
    And path 'user', username
    When method delete
