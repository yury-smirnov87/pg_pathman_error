package com.github.pg_pathman_error;

import java.sql.*;

public class App {

    private static final String URL = "jdbc:postgresql://192.168.33.10:5432/postgres";
    private static final String USER = "postgres";
    private static final String PASSWORD = "123Qwer";
    private static final int SAMPLE_ROOT_ID = 2;
    private static final String QUERY = "SELECT\n" +
            "  id,\n" +
            "  root_id,\n" +
            "  start_date,\n" +
            "  num,\n" +
            "  main,\n" +
            "  edit_num,\n" +
            "  edit_date,\n" +
            "  dict_id\n" +
            "FROM root_dict\n" +
            "WHERE root_id = ?";

    public static void main(String[] args) throws SQLException {
        System.out.println("Start testing");

        String url = URL;
        if (args.length >= 1) {
            url = args[0];
        }

        String user = USER;
        if (args.length >= 2) {
            user = args[1];
        }

        String password = PASSWORD;
        if (args.length >= 3) {
            password = args[2];
        }

        System.out.printf("Connecting to %s, user=%s\n", url, user);

        new App().testBrokenQuery(url, user, password);

        System.out.println("Finished");
    }

    private void testBrokenQuery(String url, String user, String password) throws SQLException {
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            for (int i = 1; i <= 10; i++) {
                System.out.print("Attempt " + i);
                try (PreparedStatement stmt = conn.prepareStatement(QUERY)) {

                    stmt.setLong(1, SAMPLE_ROOT_ID);

                    try (ResultSet resultSet = stmt.executeQuery()) {
                        while (resultSet.next()) {
                            long id = resultSet.getLong(1);
                            long rootId = resultSet.getLong(2);
                            Timestamp startDate = resultSet.getTimestamp(3);
                            String num = resultSet.getString(4);
                            String main = resultSet.getString(5);
                            String editNum = resultSet.getString(6);
                            Timestamp editDate = resultSet.getTimestamp(7);
                            long dictId = resultSet.getLong(8);
                        }
                    }
                }
                System.out.println(" - OK.");
            }
        }
    }
}
