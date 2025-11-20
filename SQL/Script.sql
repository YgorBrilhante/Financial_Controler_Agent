-- USERS
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,
    phone TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now() NOT NULL,
    updated_at TIMESTAMP DEFAULT now() NOT NULL
);


-- CATEGORIES
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now() NOT NULL
);

-- TRANSACTIONS
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    recurring_transaction_id UUID REFERENCES public.recurring_transactions(id),
    amount NUMERIC(10,2) NOT NULL,
    type VARCHAR(10) CHECK (type IN ('expense','income')) NOT NULL,
    description TEXT,
    transaction_date DATE NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    auto_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now() NOT NULL,
    updated_at TIMESTAMP DEFAULT now() NOT NULL
);

-- RECURRING TRANSACTIONS
CREATE TABLE IF NOT EXISTS recurring_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    amount NUMERIC(10,2) NOT NULL,
    type VARCHAR(10) CHECK (type IN ('expense','income')) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) CHECK (frequency IN ('weekly','monthly','yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    next_due_date DATE,
    last_generated DATE,
    created_at TIMESTAMP DEFAULT now() NOT NULL,
    updated_at TIMESTAMP DEFAULT now() NOT NULL
);

-- REMINDERS
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    reminder_date TIMESTAMP NOT NULL,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP,
    origin VARCHAR(20) DEFAULT 'manual' CHECK (origin IN ('manual', 'system')),
    created_at TIMESTAMP DEFAULT now() NOT NULL,
    updated_at TIMESTAMP DEFAULT now() NOT NULL
);

-- MESSAGES
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    direction VARCHAR(10) CHECK (direction IN ('in','out')) NOT NULL,
    created_at TIMESTAMP DEFAULT now() NOT NULL
);

-- SUBSCRIPTIONS
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    kiwify_id VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('active','trial','cancelled')) NOT NULL,
    plan TEXT,
    raw_json JSONB,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT now() NOT NULL,
    updated_at TIMESTAMP DEFAULT now() NOT NULL
);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notify_date TIMESTAMP NOT NULL,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now() NOT NULL
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions (user_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_recurring_user ON public.recurring_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_sent ON public.notifications (user_id, is_sent, notify_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON public.subscriptions (user_id, status);



-- Função que insere categorias padrão para o novo usuário
CREATE OR REPLACE FUNCTION create_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Despesas
    INSERT INTO categories (user_id, name) VALUES
        (NEW.id, 'Moradia'),
        (NEW.id, 'Alimentação'),
        (NEW.id, 'Transporte'),
        (NEW.id, 'Saúde'),
        (NEW.id, 'Educação'),
        (NEW.id, 'Família'),
        (NEW.id, 'Lazer'),
        (NEW.id, 'Tecnologia'),
        (NEW.id, 'Pessoais'),
        (NEW.id, 'Manutenção'),
        (NEW.id, 'Impostos'),
        (NEW.id, 'Negócios'),
        (NEW.id, 'Seguros'),
        (NEW.id, 'Documentos'),
        (NEW.id, 'Presentes'),

    -- Receitas
        (NEW.id, 'Trabalho'),
        (NEW.id, 'Autônomo'),
        (NEW.id, 'Empresa'),
        (NEW.id, 'Investimentos'),
        (NEW.id, 'Aluguéis'),
        (NEW.id, 'Benefícios'),
        (NEW.id, 'Reembolsos'),
        (NEW.id, 'Doações'),
        (NEW.id, 'Vendas'),
        (NEW.id, 'Transferências');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que chama a função logo após a criação do usuário
CREATE TRIGGER trg_create_default_categories
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION create_default_categories();



-- Função para criar a primeira transação baseada na transação recorrente recém-criada
CREATE OR REPLACE FUNCTION create_first_transaction_from_recurring()
RETURNS TRIGGER AS $$
DECLARE
    first_transaction_date DATE;
BEGIN
    -- Determina a data da primeira transação
    first_transaction_date := COALESCE(NEW.start_date, CURRENT_DATE);

    -- Insere a primeira transação vinculada à transação recorrente
    INSERT INTO transactions (
        user_id,
        category_id,
        recurring_transaction_id,
        amount,
        type,
        description,
        transaction_date,
        is_paid,
        auto_generated,
        created_at,
        updated_at
    )
    VALUES (
        NEW.user_id,
        NEW.category_id,
        NEW.id,                         -- vínculo direto
        NEW.amount,
        NEW.type,
        COALESCE(NEW.description, 'Transação recorrente inicial'),
        first_transaction_date,
        FALSE,                          -- ainda não paga
        TRUE,                           -- gerada automaticamente
        NOW(),
        NOW()
    );

    -- Atualiza o campo next_due_date para a próxima data com base na frequência
    IF NEW.frequency = 'monthly' THEN
        UPDATE recurring_transactions
        SET next_due_date = NEW.start_date + INTERVAL '1 month'
        WHERE id = NEW.id;
    ELSIF NEW.frequency = 'weekly' THEN
        UPDATE recurring_transactions
        SET next_due_date = NEW.start_date + INTERVAL '1 week'
        WHERE id = NEW.id;
    ELSIF NEW.frequency = 'yearly' THEN
        UPDATE recurring_transactions
        SET next_due_date = NEW.start_date + INTERVAL '1 year'
        WHERE id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: executa logo após a inserção de uma nova transação recorrente
CREATE TRIGGER trg_create_first_transaction_from_recurring
AFTER INSERT ON recurring_transactions
FOR EACH ROW
EXECUTE FUNCTION create_first_transaction_from_recurring();
















































