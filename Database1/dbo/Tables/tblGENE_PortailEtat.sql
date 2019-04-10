CREATE TABLE [dbo].[tblGENE_PortailEtat] (
    [iIDEtat]        INT          NOT NULL,
    [vcDescEtat]     VARCHAR (75) NOT NULL,
    [bActivation]    BIT          NOT NULL,
    [bDesactivation] BIT          NOT NULL,
    CONSTRAINT [PK_GENE_PortailEtat] PRIMARY KEY CLUSTERED ([iIDEtat] ASC) WITH (FILLFACTOR = 90)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[tblGENE_PortailEtat] TO [svc-portailmigrationprod]
    AS [dbo];

