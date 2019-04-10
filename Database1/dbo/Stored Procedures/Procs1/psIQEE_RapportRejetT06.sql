/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :    psIQEE_RapportRejetT06
Description         :    Rapport des rejets d'IQEE T06 (Impôts spéciaux).  qui est utilisé à la place de l'écran de gestion des rejets
Valeurs de retours  :    Dataset de données

Note                :    
                    2014-01-28    Donald Huppé    Création :  GLPI 10857
                    2014-06-11    Stéphane Barbeau Ajout de R.vcValeur_Erreur, clause GROUP BY, améliorations jointure avec tblIQEE_Validations   
                    2014-06-17    Stéphane Barbeau Ajout Exclure toute convention qui a des rejets non traitables
                    2018-02-08  Steeve Picard       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments

exec psIQEE_RapportRejetT06

****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_RapportRejetT06
AS
BEGIN

-- Requête pour les rejets de T06 (Impôts spéciaux)

    SELECT
        R.siAnnee_Fiscale as 'Année fiscale' 
        ,C.ConventionNo as 'Numéro de la convention' 
        ,TE.cCode_Type_Enregistrement as 'Type d''enregistrement' 
        ,STE.cCode_Sous_Type as 'Sous-Type d''enregistrement'
        ,V.iCode_Validation as 'Code de validation' 
        ,V.vcDescription as 'Description du code'
        ,IsNull(R.vcValeur_Erreur,'') as 'Valeur en erreur'
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
        JOIN tblIQEE_SousTypeEnregistrement STE ON STE.iID_Sous_Type = V.iID_Sous_Type
    WHERE TE.cCode_Type_Enregistrement = '06'
        
        -- Exclure toute convention qui a des rejets non traitables
        AND NOT EXISTS (SELECT * FROM tblIQEE_Rejets RNT 
            JOIN tblIQEE_Fichiers FNT ON FNT.iID_Fichier_IQEE = RNT.iID_Fichier_IQEE
            JOIN tblIQEE_Validations VNT ON RNT.iID_Validation = VNT.iID_Validation
            WHERE  
                RNT.iID_Convention  = C.ConventionID
                AND RNT.siAnnee_Fiscale = R.siAnnee_Fiscale
                AND VNT.bActif=1
                AND VNT.tiID_Type_Enregistrement = 5
                AND VNT.cType = 'E'
                AND VNT.bCorrection_Possible =     0
                AND VNT.iCode_Validation NOT IN (600,1100,500,300,900)
            )
                
        AND -- Exclure les conventions dont des réponses ont été reçues pour l'année fiscale concernée
        NOT EXISTS 
        (
          SELECT * FROM tblIQEE_ImpotsSpeciaux DIS1
            JOIN tblIQEE_Fichiers F1 ON DIS1.iID_Fichier_IQEE = F1.iID_Fichier_IQEE
          WHERE 
            DIS1.siAnnee_Fiscale = R.siAnnee_Fiscale 
            AND DIS1.iID_Convention= C.ConventionID
            AND DIS1.tiCode_Version IN (0,2)
            AND DIS1.cStatut_Reponse IN  ('A','R')
        )
    GROUP BY R.siAnnee_Fiscale, C.ConventionNo,TE.cCode_Type_Enregistrement, STE.cCode_Sous_Type, V.iCode_Validation 
        ,V.vcDescription, R.vcValeur_Erreur,CAST (IsNull(R.tCommentaires,'')  as nvarchar) 
    ORDER BY R.siAnnee_Fiscale,C.ConventionNo

end
