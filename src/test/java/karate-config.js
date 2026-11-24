function fn() {
  var env = karate.env || 'dev';
  karate.log('Ambiente de ejecucion:', env);

  var config = {
    env: env,
    baseUrl: 'https://petstore.swagger.io/v2'
  };

  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 10000);
  karate.configure('retry', { count: 10, interval: 1500 });

  return config;
}
