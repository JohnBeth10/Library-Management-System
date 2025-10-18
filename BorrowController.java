package controller;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.Headers;
import bll.BorrowManager;

import java.io.*;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class BorrowController {

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8081), 0);
        System.out.println("✅ Server running on http://localhost:8081 ...");

        server.createContext("/borrow", (HttpExchange exchange) -> {
            if ("POST".equals(exchange.getRequestMethod())) {
                // Read POST body
                InputStreamReader isr = new InputStreamReader(exchange.getRequestBody(), StandardCharsets.UTF_8);
                BufferedReader br = new BufferedReader(isr);
                StringBuilder body = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) body.append(line);

                // Parse form data (rollNo=1&bookId=2)
                Map<String, String> params = new HashMap<>();
                for (String pair : body.toString().split("&")) {
                    String[] kv = pair.split("=");
                    if (kv.length == 2) params.put(kv[0], kv[1]);
                }

                int rollNo = Integer.parseInt(params.get("rollNo"));
                int bookId = Integer.parseInt(params.get("bookId"));

                String message = BorrowManager.issueBook(rollNo, bookId);

                // Send response
                String response = "{\"message\": \"" + message + "\"}";
                exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
                exchange.getResponseHeaders().add("Content-Type", "application/json");
                exchange.sendResponseHeaders(200, response.getBytes().length);
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();

            } else {
                exchange.sendResponseHeaders(405, -1); // method not allowed
            }
        });

        server.start();
    }
}
