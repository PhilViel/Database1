CREATE TABLE [dbo].[tblGENE_DemandeBoursePortail] (
    [iID_DemandeBoursePortail] INT            IDENTITY (1, 1) NOT NULL,
    [vcNoConfirmation]         VARCHAR (40)   NULL,
    [dtDateCreationDemande]    DATETIME       NULL,
    [iIDBeneficiaire]          INT            NULL,
    [vcUserName]               VARCHAR (40)   NULL,
    [vcPrenomBeneficiaire]     VARCHAR (50)   NULL,
    [vcNomBeneficiaire]        VARCHAR (50)   NULL,
    [bQualifie]                BIT            NULL,
    [bResident]                BIT            NULL,
    [vcBourse]                 VARCHAR (15)   NULL,
    [vcConventions]            VARCHAR (2000) NULL,
    [vcCommentaires]           VARCHAR (250)  NULL,
    [bAttestation]             BIT            NULL,
    [vcPreuveReleve]           VARCHAR (250)  NULL,
    [vcPreuveInscription]      VARCHAR (250)  NULL
);

