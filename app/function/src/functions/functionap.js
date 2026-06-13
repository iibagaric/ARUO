import { app } from "@azure/functions";

app.http("functionap", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "functionap",
  handler: async () => ({
    jsonBody: {
      service: "function-sample",
      status: "ok",
      message: "Function App reached through Application Gateway"
    }
  })
});
