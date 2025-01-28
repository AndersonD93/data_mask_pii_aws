CREATE TABLE public.authorized_users (
    usersyid INT NOT NULL,
    usename VARCHAR(50) NOT NULL,
    pii_access BOOLEAN NOT NULL
);


INSERT INTO public.authorized_users (usersyid, usename, pii_access)
VALUES 
    (150, 'test_user_masked_sensitive_data', FALSE);


SELECT * FROM public.authorized_users;
