import express from "express";

const app = express();

app.get("/", (_req, res) => {
  res.send(Date.now().toString());
});

function fib(n: number): number {
  if (n === 1 || n === 2) {
    return 1;
  } else {
    return fib(n - 1) + fib(n - 2);
  }
}

app.get("/expensive", (_req, res) => {
  try {
    const n = 35;
    console.log(`Calculating fib of ${n}`);
    res.json({ result: fib(n) });
  } catch (e) {
    console.log(e);
  }
});

const server = app.listen(3000, () => {
  console.log("Server is running on port 3000");
});

const shutdown = () => {
  console.log("About to exit, waiting for remaining connections to complete");
  server.close(() => {
    console.log("Server closed, exiting");
    process.exit(0);
  });
};

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
