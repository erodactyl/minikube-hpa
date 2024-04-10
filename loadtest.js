for (let i = 0; i < 100; i++) {
  fetch("http://helloworld.local/expensive")
    .then((res) => res.json())
    .then(console.log);
}
