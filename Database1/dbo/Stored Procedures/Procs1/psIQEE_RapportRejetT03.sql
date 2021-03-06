﻿/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :    psIQEE_RapportRejetT03
Description         :    Rapport des rejets d'IQEE T03 (Remplacement de bénéficiaire).  qui est utilisé à la place de l'écran de gestion des rejets
Valeurs de retours  :    Dataset de données

Note                :    
                    2014-01-28    Donald Huppé        Création :  GLPI 10857
                    2014-06-11    Stéphane Barbeau    Ajout de R.vcValeur_Erreur, clause GROUP BY, améliorations jointure avec tblIQEE_Validations   
                    2014-06-16    Stéphane Barbeau    Améliorations sous-condition pour conditions fermées 'FRM'.
                    2014-06-17    Stéphane Barbeau    Exclure toute convention qui a des rejets non traitables pour ce type de convention.
                    2018-02-08  Steeve Picard       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
                    
exec psIQEE_RapportRejetT03

****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_RapportRejetT03
AS
BEGIN

-- Requête pour les rejets de T03 (Remplacement de bénéficiaire)

    SELECT 
        R.siAnnee_Fiscale as 'AnnéeFiscale' 
        ,C.ConventionNo as 'Numéro de convention'
        ,TE.cCode_Type_Enregistrement as 'TypeEnregistrement' 
        ,V.iCode_Validation as 'CodeDeValidation' 
        ,V.vcDescription as 'DescriptionDuCode'
        ,Isnull(R.vcValeur_Erreur,'') as 'Valeur en erreur'
        ,CAST (IsNull(R.tCommentaires,'')  as nvarchar) as 'Commentaire'        
        
         FROM tblIQEE_Rejets R
            JOIN dbo.Un_Convention C ON R.iID_Convention = C.ConventionID
            JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
            JOIN tblIQEE_Validations V ON R.iID_Validation = V.iID_Validation 
                                        AND V.tiID_Categorie_Erreur IN (2,7)
                                        AND V.bActif=1
                                        AND V.bCorrection_Possible=1
                                        AND V.cType='E'    
            JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
            JOIN Un_ConventionConventionState CS ON C.ConventionID = CS.ConventionID
        WHERE TE.cCode_Type_Enregistrement = '03'
            AND -- Exclure toute convention fermée
                NOT EXISTS (select * from Un_ConventionConventionState UCCS WHERE UCCS.ConventionConventionStateID 
                            IN  (select MAX(UCCS0.ConventionConventionStateID) from Un_ConventionConventionState UCCS0 where UCCS0.ConventionID = C.ConventionID ) 
                                    and UCCS.ConventionStateID='FRM')
            -- Exclure toute convention qui a des rejets non traitables pour ce type de convention
            AND 
                NOT EXISTS (SELECT * FROM tblIQEE_Rejets RNT 
                            JOIN tblIQEE_Fichiers FNT ON FNT.iID_Fichier_IQEE = RNT.iID_Fichier_IQEE
                            JOIN tblIQEE_Validations VNT ON RNT.iID_Validation = VNT.iID_Validation
                            WHERE  
                                RNT.iID_Convention  = C.ConventionID
                                AND RNT.siAnnee_Fiscale = R.siAnnee_Fiscale
                                AND VNT.bActif=1
                                AND VNT.tiID_Type_Enregistrement = 2
                                AND VNT.cType = 'E'
                                AND VNT.bCorrection_Possible = 0
                                AND VNT.iCode_Validation <> 100
                            )
            AND V.bActif=1
            AND V.bCorrection_Possible=1
            AND V.cType='E'    
            
            AND -- Exclure les conventions dont des réponses ont été reçues pour l'année fiscale concernée
            NOT EXISTS 
            (
              SELECT * FROM tblIQEE_RemplacementsBeneficiaire RB1
                JOIN tblIQEE_Fichiers F1 ON RB1.iID_Fichier_IQEE = F1.iID_Fichier_IQEE
              WHERE 
                RB1.siAnnee_Fiscale = R.siAnnee_Fiscale 
                AND RB1.iID_Convention= C.ConventionID
                AND RB1.tiCode_Version IN (0,2)
                AND RB1.cStatut_Reponse IN  ('A','R')
            )
        
        GROUP BY R.siAnnee_Fiscale, C.ConventionNo,TE.cCode_Type_Enregistrement, V.iCode_Validation 
            ,V.vcDescription, R.vcValeur_Erreur,CAST (IsNull(R.tCommentaires,'')  as nvarchar) 
        ORDER BY R.siAnnee_Fiscale, C.ConventionNo
END 
