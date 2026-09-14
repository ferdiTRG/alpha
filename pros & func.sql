#function
drop function if exists fn_cek_stok_cukup;

CREATE FUNCTION fn_cek_stok_cukup(
    p_produk_id INT,
    p_jumlah_diminta INT
)
RETURNS BOOLEAN
not DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stok_tersedia INT;

    SELECT stok INTO v_stok_tersedia
      FROM PRODUK
     WHERE id = p_produk_id;

    IF v_stok_tersedia IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN v_stok_tersedia >= p_jumlah_diminta;
END;

#prosedur
CREATE PROCEDURE sp_buat_pesanan (
    IN p_customer_id INT,
    IN p_produk_id INT,
    IN p_jumlah INT,
    OUT p_pesanan_id INT,
    OUT p_pesan VARCHAR(255)
)
BEGIN
    DECLARE v_harga DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);

    IF NOT fn_cek_stok_cukup(p_produk_id, p_jumlah) THEN
        SET p_pesanan_id = NULL;
        SET p_pesan = 'Stok tidak cukup untuk produk ini.';
    ELSE
        SELECT harga INTO v_harga FROM PRODUK WHERE id = p_produk_id;
        SET v_total = v_harga * p_jumlah;

        INSERT INTO PESANAN (customer_id, status, total_bayar, created_at)
        VALUES (p_customer_id, 'pending', v_total, NOW());

        SET p_pesanan_id = LAST_INSERT_ID();

        INSERT INTO DETAIL_PESANAN (pesanan_id, produk_id, jumlah, subtotal)
        VALUES (p_pesanan_id, p_produk_id, p_jumlah, v_total);

        SET p_pesan = CONCAT('Pesanan berhasil dibuat dengan id ', p_pesanan_id,
                              ', total Rp ', v_total);
    END IF;
END;
