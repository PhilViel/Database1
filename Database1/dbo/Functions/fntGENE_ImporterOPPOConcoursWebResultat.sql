CREATE FUNCTION [dbo].[fntGENE_ImporterOPPOConcoursWebResultat]
(@iParaSansDate INT, @iParaOperation INT, @nvUsager NVARCHAR (255), @nvMotPasse NVARCHAR (255), @nvParaURL NVARCHAR (255))
RETURNS 
     TABLE (
        [ID_Source]       NVARCHAR (255) NULL,
        [DateEntree]      NVARCHAR (255) NULL,
        [Code_Provenance] NVARCHAR (255) NULL,
        [Salutation]      NVARCHAR (255) NULL,
        [Nom]             NVARCHAR (255) NULL,
        [Prenom]          NVARCHAR (255) NULL,
        [Adresse]         NVARCHAR (255) NULL,
        [Ville]           NVARCHAR (255) NULL,
        [Province]        NVARCHAR (255) NULL,
        [CodePostal]      NVARCHAR (255) NULL,
        [Residence]       NVARCHAR (255) NULL,
        [Bureau]          NVARCHAR (255) NULL,
        [Occupation]      NVARCHAR (255) NULL,
        [Reference]       NVARCHAR (255) NULL,
        [Enfant1]         NVARCHAR (255) NULL,
        [Enfant2]         NVARCHAR (255) NULL,
        [Enfant3]         NVARCHAR (255) NULL,
        [Enfant4]         NVARCHAR (255) NULL,
        [DateNais1]       NVARCHAR (255) NULL,
        [DateNais2]       NVARCHAR (255) NULL,
        [DateNais3]       NVARCHAR (255) NULL,
        [DateNais4]       NVARCHAR (255) NULL,
        [Parente]         NVARCHAR (255) NULL,
        [Renseignement]   NVARCHAR (255) NULL,
        [Promotion]       NVARCHAR (255) NULL,
        [Connaitre]       NVARCHAR (255) NULL,
        [Specification]   NVARCHAR (255) NULL,
        [Commentaire]     NVARCHAR (MAX) NULL,
        [Tracage]         NVARCHAR (255) NULL,
        [Appel]           NVARCHAR (255) NULL,
        [Courriel]        NVARCHAR (255) NULL,
        [Annee]           NVARCHAR (255) NULL,
        [ID_Concour]      NVARCHAR (255) NULL,
        [Langue]          NVARCHAR (255) NULL,
        [Regime]          NVARCHAR (255) NULL,
        [Rencontre]       NVARCHAR (255) NULL)
AS
 EXTERNAL NAME [assSQLCommonFunctions].[SQLCommonFunctions.OPPO].[Importer_Participants]

