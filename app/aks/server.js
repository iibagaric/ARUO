import express from "express";

const app = express();
const port = process.env.PORT || 8080;

app.get(["/", "/aks"], (_req, res) => {
  res.json({
    service: "aks-sample",
    status: "ok",
    message: "AKS sample application reached through Application Gateway"
  });
});

app.get("/healthz", (_req, res) => {
  res.status(200).send("ok");
});

app.listen(port, () => {
  console.log(`AKS sample app listening on ${port}`);
});

