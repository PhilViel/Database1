CREATE TABLE [dbo].[Un_CESP800SIN] (
    [tyCESP800SINID] TINYINT       NOT NULL,
    [vcCESP800SIN]   VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP800SIN] PRIMARY KEY CLUSTERED ([tyCESP800SINID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des réponses possibles sur la validité du NAS des enregistrements 800', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800SIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la réponse sur la validité du NAS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800SIN', @level2type = N'COLUMN', @level2name = N'tyCESP800SINID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Réponse sur la validité du NAS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800SIN', @level2type = N'COLUMN', @level2name = N'vcCESP800SIN';

