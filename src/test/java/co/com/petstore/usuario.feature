@usuario
Feature: Gestión de usuarios en la API PetStore
  Como QA quiero validar el ciclo de vida de un usuario en https://petstore.swagger.io
  para asegurar que se puede crear, consultar, actualizar y eliminar correctamente.

  Background:
    * url baseUrl
    * def esquemaUsuario = read('data/esquema-usuario.json')
    * def esquemaRespuesta = { code: 200, type: 'unknown', message: '#string' }
    * def timestamp = java.lang.System.currentTimeMillis()
    * def userId = timestamp
    * def username = 'jonacast_' + timestamp
    * def usuario = read('data/usuario.json')
    * def cambios = read('data/actualizacion-usuario.json')
    * def usuarioActualizado = karate.merge(usuario, cambios)
    * def crearUsuario = 'classpath:co/com/petstore/helpers/crear-usuario.feature'
    * def actualizarUsuario = 'classpath:co/com/petstore/helpers/actualizar-usuario.feature'
    * configure afterScenario = function(){ karate.call('classpath:co/com/petstore/helpers/eliminar-usuario.feature', { username: karate.get('username') }) }

  @crear
  Scenario: Crear un usuario
    * print 'Entrada - usuario a crear:', usuario
    Given path 'user'
    And request usuario
    When method post
    Then status 200
    And match response == esquemaRespuesta
    And match response.message == userId + ''
    * print 'Salida - respuesta de la creación:', response

  @buscar
  Scenario: Buscar el usuario creado
    * def creacion = call read(crearUsuario) { usuario: '#(usuario)' }
    * print 'Entrada - username a buscar:', username
    Given path 'user', username
    And retry until responseStatus == 200
    When method get
    Then status 200
    And match response == esquemaUsuario
    And match response == usuario
    * print 'Salida - usuario encontrado:', response

  @actualizar
  Scenario: Actualizar el nombre y el correo del usuario
    * def creacion = call read(crearUsuario) { usuario: '#(usuario)' }
    * print 'Entrada - cambios a aplicar (solo nombre y correo):', cambios
    Given path 'user', username
    And request usuarioActualizado
    When method put
    Then status 200
    And match response == esquemaRespuesta
    And match response.message == userId + ''
    * print 'Salida - respuesta de la actualización:', response

  @buscar-actualizado
  Scenario: Buscar el usuario actualizado
    * def creacion = call read(crearUsuario) { usuario: '#(usuario)' }
    * def actualizacion = call read(actualizarUsuario) { usuarioActualizado: '#(usuarioActualizado)' }
    * print 'Entrada - username a buscar:', username
    Given path 'user', username
    And retry until responseStatus == 200 && response.firstName == cambios.firstName && response.email == cambios.email
    When method get
    Then status 200
    And match response == esquemaUsuario
    And match response == usuarioActualizado
    And match response contains { lastName: '#(usuario.lastName)', phone: '#(usuario.phone)', password: '#(usuario.password)' }
    * print 'Salida - usuario actualizado:', response

  @eliminar
  Scenario: Eliminar el usuario
    * def creacion = call read(crearUsuario) { usuario: '#(usuario)' }
    * print 'Entrada - username a eliminar:', username
    Given path 'user', username
    And retry until responseStatus == 200
    When method delete
    Then status 200
    And match response == { code: 200, type: 'unknown', message: '#(username)' }
    * print 'Salida - respuesta de la eliminación:', response

    Given path 'user', username
    And retry until responseStatus == 404
    When method get
    Then status 404
    And match response == { code: 1, type: 'error', message: 'User not found' }
    * print 'Salida - consulta posterior a la eliminación:', response

  @hallazgo
  Scenario: Hallazgo - el PUT ignora el username de la URL y actualiza el usuario del body
    * def creacion = call read(crearUsuario) { usuario: '#(usuario)' }
    * def usernameUrl = 'userSofka'
    * print 'Entrada - username en la URL del PUT:', usernameUrl
    * print 'Entrada - body del PUT (pertenece a otro usuario):', usuarioActualizado
    Given path 'user', usernameUrl
    And request usuarioActualizado
    When method put
    Then status 200
    And match response == esquemaRespuesta
    And match response.message == userId + ''
    * print 'Salida - respuesta del PUT a userSofka:', response

    Given path 'user', username
    And retry until responseStatus == 200 && response.firstName == cambios.firstName && response.email == cambios.email
    When method get
    Then status 200
    And match response == usuarioActualizado
    * print 'Salida - el usuario del body quedó modificado:', response

    Given path 'user', usernameUrl
    When method get
    Then status 404
    And match response == { code: 1, type: 'error', message: 'User not found' }
    * print 'Salida - userSofka no existe ni fue creado:', response

  @negativo
  Scenario: Buscar un usuario que no existe retorna 404
    * def usernameInexistente = 'no_existe_' + timestamp
    Given path 'user', usernameInexistente
    When method get
    Then status 404
    And match response == { code: 1, type: 'error', message: 'User not found' }
