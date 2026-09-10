<?php
/**
 * HealthExpress AI - Admin Operations Controller
 * Calculates all KPIs and analytics directly from Live Hostinger MySQL
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';

class AdminController {
    /**
     * Compute Real-time Dashboard KPI Metrics
     */
    public static function getStats(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            (SELECT COUNT(*) FROM users) AS total_users,
            (SELECT COUNT(*) FROM doctors) AS total_doctors,
            (SELECT COUNT(*) FROM hospitals) AS total_hospitals,
            (SELECT COUNT(*) FROM appointments) AS total_appointments,
            (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'paid') AS gross_revenue,
            (SELECT COUNT(*) FROM doctors WHERE verification_status = 'pending') AS pending_doctors,
            (SELECT COUNT(*) FROM hospitals WHERE verification_status = 'pending') AS pending_hospitals,
            (SELECT COUNT(*) FROM tickets WHERE status = 'open') AS open_tickets";

        $stmt = $pdo->query($query);
        $stats = $stmt->fetch();

        Response::json($stats);
    }

    /**
     * Compute Real-time AI Triage & Voice Consultation Metrics
     */
    public static function getAiStats(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            (SELECT COUNT(*) FROM ai_sessions) AS total_ai_sessions,
            (SELECT COUNT(*) FROM ai_sessions WHERE duration LIKE '%min%' OR symptoms LIKE '%voice%') AS voice_consultations,
            (SELECT COUNT(*) FROM ai_sessions WHERE severity = 'Emergency') AS emergency_escalations,
            (SELECT COUNT(*) FROM ai_sessions WHERE severity = 'Moderate') AS moderate_cases,
            (SELECT COUNT(*) FROM ai_sessions WHERE severity = 'Mild') AS mild_cases";

        $stmt = $pdo->query($query);
        $aiStats = $stmt->fetch();

        Response::json($aiStats);
    }

    /**
     * Get Recent AI Triage Sessions with Patient Details
     */
    public static function getAiSessions(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            s.*,
            u.name AS patient_name,
            u.city AS patient_city,
            u.profile_picture AS patient_avatar,
            d.name AS recommended_doctor_name,
            d.specialty AS recommended_doctor_specialty
        FROM ai_sessions s
        LEFT JOIN users u ON s.user_id = u.id
        LEFT JOIN doctors d ON s.recommended_doctor_id = d.id
        ORDER BY s.created_at DESC
        LIMIT 20";

        $stmt = $pdo->query($query);
        $sessions = $stmt->fetchAll();

        Response::json($sessions);
    }

    /**
     * Top Hospitals Volume Rankings
     */
    public static function getHospitalRankings(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            h.id, 
            h.name, 
            COUNT(a.id) AS bookings 
        FROM hospitals h
        LEFT JOIN doctor_hospitals dh ON h.id = dh.hospital_id
        LEFT JOIN appointments a ON dh.doctor_id = a.doctor_id
        GROUP BY h.id, h.name
        ORDER BY bookings DESC
        LIMIT 5";

        $stmt = $pdo->query($query);
        $rankings = $stmt->fetchAll();

        Response::json($rankings);
    }

    /**
     * Consultation Distribution by Mode
     */
    public static function getConsultationDistribution(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            consultation_type, 
            COUNT(*) AS count 
        FROM appointments 
        GROUP BY consultation_type";

        $stmt = $pdo->query($query);
        $distribution = $stmt->fetchAll();

        Response::json($distribution);
    }

    /**
     * Live Operational Activity & Audit Trail
     */
    public static function getActivityLogs(): void {
        $pdo = Database::getConnection();

        $query = "SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 10";
        $stmt = $pdo->query($query);
        $logs = $stmt->fetchAll();

        Response::json($logs);
    }

    /**
     * Get All Registered Patients & Health Profiles
     */
    public static function getUsers(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            u.id, u.name, u.phone, u.email, u.aarogyasri_id, u.role, u.created_at,
            hp.blood_group, hp.allergies, hp.past_surgeries, hp.current_medications, hp.completion_percent
        FROM users u
        LEFT JOIN health_profiles hp ON u.id = hp.user_id
        ORDER BY u.created_at DESC";

        $stmt = $pdo->query($query);
        $users = $stmt->fetchAll();

        Response::json($users);
    }

    /**
     * Get All Payment Transactions
     */
    public static function getPayments(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            p.*,
            u.name AS user_name,
            u.phone AS user_phone,
            a.doctor_id,
            d.name AS doctor_name,
            d.specialty AS doctor_specialty
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN appointments a ON p.appointment_id = a.id
        LEFT JOIN doctors d ON a.doctor_id = d.id
        ORDER BY p.created_at DESC";

        $stmt = $pdo->query($query);
        $payments = $stmt->fetchAll();

        Response::json($payments);
    }

    /**
     * Get All Central Appointments
     */
    public static function getAllAppointments(): void {
        $pdo = Database::getConnection();

        $query = "SELECT 
            a.*,
            u.name AS patient_name,
            u.phone AS patient_phone,
            u.aarogyasri_id,
            d.name AS doctor_name,
            d.specialty AS doctor_specialty,
            COALESCE(h.name, 'Independent Practice') AS hospital_name
        FROM appointments a
        JOIN users u ON a.user_id = u.id
        JOIN doctors d ON a.doctor_id = d.id
        LEFT JOIN doctor_hospitals dh ON d.id = dh.doctor_id AND dh.is_primary = 1
        LEFT JOIN hospitals h ON dh.hospital_id = h.id
        ORDER BY a.created_at DESC";

        $stmt = $pdo->query($query);
        $appts = $stmt->fetchAll();

        Response::json($appts);
    }
}
