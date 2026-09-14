CREATE TABLE ADMIN (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE CUSTOMER (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    no_hp VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PRODUK (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    kategori VARCHAR(50),
    harga DECIMAL(10,2) NOT NULL,
    stok INT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PESANAN (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_bayar DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER(id)
);

CREATE TABLE DETAIL_PESANAN (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pesanan_id INT NOT NULL,
    produk_id INT NOT NULL,
    jumlah INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (pesanan_id) REFERENCES PESANAN(id),
    FOREIGN KEY (produk_id) REFERENCES PRODUK(id)
);

CREATE TABLE STOK_LOG (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produk_id INT NOT NULL,
    admin_id INT NULL,
    perubahan INT NOT NULL,
    alasan VARCHAR(100),
    waktu DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produk_id) REFERENCES PRODUK(id),
    FOREIGN KEY (admin_id) REFERENCES ADMIN(id)
);

# data dummy

INSERT INTO ADMIN (username, password) VALUES
('busari', 'hash_password_admin');

INSERT INTO CUSTOMER (nama, email, no_hp, password) VALUES
('sucipto', 'ggs@email.com', '089921993213', 'supri123');

INSERT INTO PRODUK (id, nama, kategori, harga, stok) VALUES
(1, 'Indomie Goreng', 'Makanan Instan', 3000, 50),
(2, 'Aqua Botol 600ml', 'Minuman', 5000, 30),
(3, 'Kecap ABC 220ml', 'Bumbu Dapur', 9000, 44);

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


CALL sp_buat_pesanan(2, 2, 2, @pesanan_id, @pesan);
SELECT @pesanan_id, @pesan;

CALL sp_buat_pesanan(3, 2, 5, @pesanan_id2, @pesan2);
SELECT @pesanan_id2, @pesan2;

select
if(fn_cek_stok_cukup(1, 5), 'stock cukup', 'stock kurang') AS Stock;

SELECT customer_id, status, from PESANAN;

SELECT CUSTOMER.nama, DETAIL_PESANAN.produk_id, DETAIL_PESANAN.jumlah, DETAIL_PESANAN.subtotal, PRODUK.nama, PESANAN.status from CUSTOMER
join PESANAN on CUSTOMER.id = PESANAN.customer_id
join DETAIL_PESANAN on PESANAN.id = DETAIL_PESANAN.pesanan_ID
join PRODUK on PRODUK.id = DETAIL_PESANAN.produk_id;

select DETAIL_PESANAN.subtotal, DETAIL_PESANAN.jumlah from CUSTOMER
join PESANAN on CUSTOMER.id = PESANAN.customer_id
join DETAIL_PESANAN on PESANAN.id = DETAIL_PESANAN.pesanan_ID;

CALL sp_buat_pesanan(2, 2, 2, @pesanan_id, @pesan);
