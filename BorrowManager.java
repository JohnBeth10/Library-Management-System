package bll;
import java.sql.*;
import dao.DatabaseConnection;

public class BorrowManager {

    public static String issueBook(int rollNo, int bookId) {
        String message = "";

        try (Connection conn = DatabaseConnection.getConnection()) {
            CallableStatement stmt = conn.prepareCall("{CALL Issue_Book(?, ?, NULL, DATE_ADD(CURDATE(), INTERVAL 14 DAY))}");
            stmt.setInt(1, rollNo);
            stmt.setInt(2, bookId);

            boolean hasResult = stmt.execute();
            if (hasResult) {
                ResultSet rs = stmt.getResultSet();
                if (rs.next()) message = rs.getString("Message");
            } else {
                message = "No response from procedure.";
            }

        } catch (SQLException e) {
            message = "Error issuing book: " + e.getMessage();
            e.printStackTrace();
        }

        return message;
    }
}
