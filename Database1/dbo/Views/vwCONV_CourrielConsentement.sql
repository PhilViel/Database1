/**********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : vwCONV_CourrielConsentement
But                : Retourne les consentements 

Historique des modifications:
    Date        Programmeur                    Description                                        
    ----------  ------------------------    -----------------------------------------------------------------------
    2016-05-30  Steeve Picard               Création du service            
    2016-06-03  Patrice Côté                Ajout de l'appel de la fonction fnCONV_EstTaciteEnVigueur
    2016-08-01  Steeve Picard               Ajout de colonnes «dtDate_» & «vcLogin_»
***********************************************************************************************************************/
CREATE VIEW [dbo].[vwCONV_CourrielConsentement]
AS

    SELECT CC.iID_CourrielConsentement, H.HumanID, CTE.iID_CourrielTypeEnvoi, CTE.vcLibelleFrancais, CTE.vcLibelleAnglais,
           tiTypeConsentement = CAST(CASE WHEN CC.bAutoriser = 0 THEN 0
                                          WHEN CC.bAutoriser = 1 THEN 1
                                          WHEN S.SubscriberID IS NOT NULL THEN 
											  CASE WHEN GetDate() <= S.dtFinEntenteTacite THEN 2
												ELSE 3
											  END	
                                          ELSE 3
                                     END as int),
           dtTaciteExpiration = S.dtFinEntenteTacite,
           CC.dtDate_Modification, CC.vcLogin_Modification,
           CC.dtDate_Creation, CC.vcLogin_Creation
      FROM dbo.Mo_Human H
		 LEFT JOIN fntCONV_ObtenirSouscripteurDateFinEntenteTacite (DEFAULT) S ON S.SubscriberID = H.HumanID
           CROSS JOIN dbo.tblCONV_CourrielTypeEnvoi CTE --ON CTE.iID_CourrielTypeEnvoi = CC.iID_CourrielTypeEnvoi
           LEFT JOIN dbo.tblCONV_CourrielConsentement CC ON CC.iID_Human = H.HumanID AND CTE.iID_CourrielTypeEnvoi = CC.iID_CourrielTypeEnvoi
--WHERE CC.bAutoriser is not null


GO
/**********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : vwCONV_CourrielConsentement_I
But                : Créer de nouveaux consentements dans la table tblCONV_CourrielConsentement

Historique des modifications:
    Date            Programmeur                    Description                                        
    ----------      ------------------------    -----------------------------------------------------------------------
    2016-05-30        Steve Picard                Création du service            

***********************************************************************************************************************/
CREATE TRIGGER [dbo].[trgVW_CourrielConsentement_I] ON [dbo].[vwCONV_CourrielConsentement]
INSTEAD OF INSERT
AS
BEGIN
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    DECLARE @vcTriggerName varchar(50) = OBJECT_NAME(@@PROCID),
            @Now datetime = GetDate()
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE @vcTriggerName like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END
    PRINT @vcTriggerName + ' - Start'

    --    Bloque le trigger des DELETEs
    INSERT INTO #DisableTrigger VALUES(@vcTriggerName)
    
    INSERT INTO dbo.tblCONV_CourrielConsentement (iID_Human, iID_CourrielTypeEnvoi, bAutoriser)
    SELECT I.HumanID, I.iID_CourrielTypeEnvoi, 
           Cast(CASE WHEN I.tiTypeConsentement IN (0,1) THEN I.tiTypeConsentement ELSE NULL END as bit)
      FROM inserted I

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = @vcTriggerName

    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
    PRINT @vcTriggerName + ' - End'
END

GO
/**********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : vwCONV_CourrielConsentement_U
But                : Met à jour des consentements dans la table tblCONV_CourrielConsentement

Historique des modifications:
    Date            Programmeur                    Description                                        
    ----------      ------------------------    -----------------------------------------------------------------------
    2016-05-30        Steve Picard                Création du service            

***********************************************************************************************************************/
CREATE TRIGGER [dbo].[trgVW_CourrielConsentement_U] ON [dbo].[vwCONV_CourrielConsentement]
INSTEAD OF UPDATE
AS
BEGIN
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
    DECLARE @vcTriggerName varchar(50) = OBJECT_NAME(@@PROCID),
            @Now datetime = GetDate()
    
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE
    BEGIN
        -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
        -- ne soit pas à exécuter
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE @vcTriggerName like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END
    PRINT @vcTriggerName + ' - Start'

    --    Bloque le trigger des DELETEs
    INSERT INTO #DisableTrigger VALUES(@vcTriggerName)

    --MERGE INTO dbo.tblCONV_CourrielConsentement as CC
    --     USING (SELECT HumanID, iID_CourrielTypeEnvoi FROM inserted) as I(HumanID, iID_CourrielTypeEnvoi, tiTypeConsentement)
    --        ON (I.HumanID = CC.iID_Human AND I.iID_CourrielTypeEnvoi = CC.iID_CourrielTypeEnvoi)
    --     WHEN MATCHED THEN
    --        UPDATE SET bAutoriser = CAST(I.tiTypeConsentement as bit)
    --     WHEN NOT MATCHED BY CC THEN
    --        INSERT ()

    UPDATE CC
    SET bAutoriser = CAST(I.tiTypeConsentement as bit)
      FROM dbo.tblCONV_CourrielConsentement CC
           JOIN inserted I ON I.HumanID = CC.iID_Human AND I.iID_CourrielTypeEnvoi = CC.iID_CourrielTypeEnvoi
     WHERE I.tiTypeConsentement IN (0, 1)
       AND I.tiTypeConsentement <> IsNull(Cast(CC.bAutoriser as tinyint), 3)

    INSERT INTO dbo.tblCONV_CourrielConsentement (iID_Human, iID_CourrielTypeEnvoi, bAutoriser)
    SELECT I.HumanID, I.iID_CourrielTypeEnvoi, 
           Cast(CASE WHEN I.tiTypeConsentement IN (0,1) THEN I.tiTypeConsentement ELSE NULL END as bit)
      FROM inserted I
           LEFT JOIN dbo.tblCONV_CourrielConsentement D ON I.HumanID = D.iID_Human AND I.iID_CourrielTypeEnvoi = D.iID_CourrielTypeEnvoi
     WHERE D.iID_CourrielConsentement IS NULL
           
    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = @vcTriggerName

    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
    PRINT @vcTriggerName + ' - End'
END
