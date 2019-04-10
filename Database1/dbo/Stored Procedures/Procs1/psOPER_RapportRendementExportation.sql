/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	psOPER_RapportRendementExportation
Description         :	Procédure qui permet d'afficher ou importer les taux de rendements provenant d'un fichier excel

Exemple d'appel		:
	exec psOPER_RapportRendementExportation '20130630_tab_grilleRendement.xls', 'univeristas\mmartel', 0

Note                :	2013-07-19	Maxime Martel		Création
						2014-02-27	Pierre-Luc Simard	Dossier 2014
						2014-12-10	Donald Huppé			Ajout d'une validation pour éviter d'importer des taux plus d'une fois.
						2015-03-10	Pierre-Luc Simard	Vérifier si le fichier est ouvert avant de faire l'importation
						2015-04-28	Donald Huppé		ajout de jtessier
						2017-03-17	Donald Huppé		ajout de jfpakenham
                        2017-06-15  Pierre-Luc Simard   Ajout de hdehbi
                        2017-12-12	Pierre-Luc Simard	Retrait de jfpakenham (JIRA TI-10220)
						2017-12-14	Donald Huppé		Ajout de cverreault
						2018-02-14	Donald Huppé		Ajout de ysellami
						2018-11-12  Maxime Martel		Ajout du plan id 13 pour le reeeflex
                        2018-11-13  Pierre-Luc Simard   Utilisation des regroupements de régimes

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportRendementExportation] (
    @FName VARCHAR(255) ,
    @loginName VARCHAR(255) ,
    @Importation BIT)
AS
BEGIN
    BEGIN TRY
        DECLARE
            @Directory VARCHAR(2000) ,
            @MyString VARCHAR(2000) ,
            @Source VARCHAR(2000) ,
            @univ DECIMAL(20, 3) ,
            @univ1 DECIMAL(20, 3) ,
            @reeeflex DECIMAL(20, 3) ,
            @reeeflex1 DECIMAL(20, 3) ,
            @indiv DECIMAL(20, 3) ,
            @indiv1 DECIMAL(20, 3) ,
            @type VARCHAR(100) ,
            @typeRendement INT ,
            @i INTEGER ,
            @dateOPER DATETIME ,
            @dateOPERPasEncoreCalculé DATETIME ,
            @dateDernierRendementInséré DATETIME ,
            @UserID INTEGER ,
            @iID_TauxRendement INT ,
            @cMessage NVARCHAR(MAX) ,
            @retour INT

        IF NOT EXISTS ( 
						SELECT
                            1
                        FROM sysobjects
                        WHERE name = 'tblTEMP_Importation' )
            BEGIN
                CREATE TABLE tblTEMP_Importation (
                    userID INTEGER ,
                    loginName VARCHAR(255) ,
                    nomFichier VARCHAR(255) ,
                    DateInsert DATETIME) --drop table tblTEMP_Importation
            END

        IF (@Importation = 0)
            BEGIN
                DELETE FROM tblTEMP_Importation
                WHERE loginName = @loginName
                    AND nomFichier = @FName
                INSERT  INTO tblTEMP_Importation
                VALUES (@UserID, @loginName, @FName, GETDATE())
            END

        SET @Directory = '\\filesprod\plandeclassification\5_COMPTABILITE_ET_INFO_FINANCIERES\503_FIN_ET_PLACEMENT\503-100_PLACEMENT\503-101_TAUX\2015'
									--dbo.fnGENE_ObtenirParametre ('DOSSIER_FICHIER_RENDEMENT',NULL,NULL,NULL,NULL,NULL,NULL)

        SET @cMessage = ''

		-- Vérifier si le fichier est déjà ouvert
        DECLARE
            @vcCommande VARCHAR(250) ,
            @vcChemin VARCHAR(250) ,
            @vcUtilisateur VARCHAR(50)

        SET @vcChemin = '5_COMPTABILITE_ET_INFO_FINANCIERES\503_FIN_ET_PLACEMENT\503-100_PLACEMENT\503-101_TAUX\2015' + '\' + @FName

        CREATE TABLE #tblTEMP_Resultat (
            id INT IDENTITY(1, 1) ,
            line NVARCHAR(1000))

        SET @vcCommande = 'C:\Scripts\PsFile\psfile \\srvapp06 -u svc_openfiles -p hn2ZfNM5aqOe9mOjqmpq'

        INSERT  INTO #tblTEMP_Resultat
                (line)
                EXEC xp_cmdshell @vcCommande

		-- Retourner les valeurs
        SELECT TOP 1
			@vcUtilisateur = SUBSTRING(U.line, 13, LEN(U.line))
        FROM #tblTEMP_Resultat F
        JOIN #tblTEMP_Resultat U ON U.id = F.id + 1
        WHERE LEFT(F.line, 1) = '['
            AND REVERSE(LEFT(REVERSE(F.line), CHARINDEX(']', REVERSE(F.line)) - 1)) <> ' \srvsvc'
            AND (@vcChemin = ''
                 OR REVERSE(LEFT(REVERSE(F.line), CHARINDEX(']', REVERSE(F.line)) - 1)) LIKE '%' + @vcChemin + '%')

        DROP TABLE #tblTEMP_Resultat

        IF @vcUtilisateur IS NOT NULL AND ISNULL(@vcUtilisateur, '') NOT LIKE '%service%'
            BEGIN
                SET @cMessage = 'Attention. Demandez d''abord à l''utilisateur ' + @vcUtilisateur + ' de fermer le fichier.'
                SET @Importation = 0
				SELECT
					1,
                    'Attention!',
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    GETDATE() AS date_operation ,
                    @cMessage AS message
            END	
        ELSE
            BEGIN 
                IF (@Importation <> 0)
                    AND NOT EXISTS ( 
									SELECT *
                                     FROM tblTEMP_Importation
                                     WHERE loginName = @loginName
                                        AND nomFichier = @FName )
                    BEGIN
                        SET @cMessage = 'Attention. Demandez d''abord d''afficher les taux sans importer.'
                        SET @Importation = 0
                    END

                IF EXISTS ( 
							SELECT name
                            FROM sysobjects
                            WHERE name = 'tmpRendement' )
                    BEGIN
                        DROP TABLE tmpRendement
                    END

                SET @loginName = SUBSTRING(@loginName, CHARINDEX('\', @loginName, 1) + 1, 99)
                SELECT
                    @UserID = UserID
                FROM Mo_User
                WHERE LoginNameID = @loginName

                SELECT
                    @dateOPER = MAX(dtDate_Operation)
                FROM tblOPER_TauxRendement 
                SELECT
                    @dateOPER = DATEADD(DAY, -1, DATEADD(MONTH,
                                                DATEDIFF(MONTH, 0, @dateOPER) + 2, 0))

                SET @Source = 'Excel 12.0 Xml;Database=' + @Directory + '\' + @FName
                SET @MyString = 'SELECT a.id, a.[Type de rendement], a.[No taux], a.UNIVERSITAS, 
									a.[UNIVERSITAS RIN - 12 mois] as universitas1,
									a.REEEFLEX, a.[REEEFLEX RIN - 12 mois] as reeeflex1, 
									a.[INDIVIDUEL incluant les transferts TRI] as individuelAvant_RI, 
									a.[INDIVIDUEL issu d''un transfert RIO ou RIM  (T et M)] as individuelApres_RI, 
									a.idTypeRendement into tmpRendement
									FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', '''
                    + @Source + ''',	''SELECT * FROM [Feuil1$]'') AS a'
                EXEC (@MyString)

                IF LTRIM(RTRIM(@cMessage)) = ''
                    BEGIN
                        SET @cMessage = 'Vous allez importer les taux suivants :'
                    END

                IF @loginName NOT LIKE '%mcbreton%'
                    -- AND @loginName NOT LIKE '%jfpakenham%'
                    -- AND @loginName NOT LIKE '%amainguy%'
                    AND @loginName NOT LIKE '%dhuppe%'
					AND @loginName NOT LIKE '%jtessier%'
                    AND @loginName NOT LIKE '%hdehbi%'
					AND @loginName NOT LIKE '%cverreault%'
					AND @loginName NOT LIKE '%ysellami%'
                    AND @Importation = 1
                    BEGIN
                        SET @cMessage = 'Usager non autorisé pour l''importation : ' + @loginName
                        SET @Importation = 0
                    END

				SELECT
                    @dateOPERPasEncoreCalculé = dtDate_Operation ,
                    @dateDernierRendementInséré = dtDate_Debut_Application
                FROM tblOPER_TauxRendement
                WHERE iID_Operation IS NULL
                IF @dateOPERPasEncoreCalculé IS NOT NULL
                    BEGIN
                        SET @cMessage = 'Ligne 3 : DES TAUX ONT DÉJÀ ÉTÉ IMPORTÉS LE  '
                            + CAST(@dateDernierRendementInséré AS VARCHAR)
                            + ' pour le mois se terminant le '
                            + CAST(LEFT(CONVERT(VARCHAR, @dateOPERPasEncoreCalculé, 120), 10) AS VARCHAR) + ' !!!'
                        SET @Importation = 0
                        UPDATE tmpRendement
                        SET [Type de rendement] = '-------------- > Erreur  (voir message ligne 3)'
                    END

                IF @Importation = 1
                    BEGIN
                        DECLARE MyCursor CURSOR
                        FOR
                        SELECT
                            universitas ,
                            UNIVERSITAS1 ,
                            REEEFLEX ,
                            REEEFLEX1 ,
                            individuelAvant_RI ,
                            individuelApres_RI ,
                            idTypeRendement
                        FROM tmpRendement
                        WHERE [Type de rendement] IS NOT NULL
                        OPEN MyCursor
                        FETCH MyCursor INTO @univ, @univ1, @reeeflex,
                            @reeeflex1, @indiv, @indiv1, @typeRendement

                        SET @i = 1

                        WHILE @@FETCH_STATUS = 0
                            AND @i <= 12
                            BEGIN

                                IF @i = 1
                                    OR @i = 2
                                    BEGIN

                                        IF @indiv <> 0
                                            BEGIN

                                                EXECUTE @retour = psOPER_AjouterTauxRendement NULL, @dateOPER, @typeRendement, 0, @UserID, '', 'A'

                                                IF @retour = 0
                                                    BEGIN

                                                        SELECT
                                                            @iID_TauxRendement = MAX(iID_Taux_Rendement)
                                                        FROM tblOPER_TauxRendement
                                                        INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement ,
                                                              PlanID ,
                                                              dTaux_AvantDelaiRI ,
                                                              dTaux_ApresDelaiRI ,
                                                              dTaux_Individuel ,
                                                              dTaux_Individuel_RIO)
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              4 ,
                                                              NULL ,
                                                              NULL ,
                                                              @indiv ,
                                                              NULL)
                                                    END
                                            END
                                    END
                                ELSE
                                    BEGIN
                                        IF (@univ <> 0
                                            OR @univ1 <> 0
                                            OR @reeeflex <> 0
                                            OR @reeeflex1 <> 0
                                            OR @indiv <> 0
                                            OR @indiv1 <> 0
                                           )
                                            BEGIN
                                                EXECUTE @retour = psOPER_AjouterTauxRendement NULL, @dateOPER, @typeRendement, 0, @UserID, '', 'A'

                                                IF @retour = 0
                                                    BEGIN

                                                        SELECT
                                                            @iID_TauxRendement = MAX(iID_Taux_Rendement)
                                                        FROM tblOPER_TauxRendement

								--UNIVERSITAS
                                                        INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement,
                                                              PlanID,
                                                              dTaux_AvantDelaiRI,
                                                              dTaux_ApresDelaiRI,
                                                              dTaux_Individuel,
                                                              dTaux_Individuel_RIO)
                                                        SELECT 
                                                            @iID_TauxRendement,
                                                            P.PlanID,
                                                            @univ,
                                                            @univ1,
                                                            NULL,
                                                            NULL
                                                        FROM Un_Plan P
                                                        JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
                                                        WHERE RR.vcCode_Regroupement = 'UNI'

                                                        /*
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              8 ,
                                                              @univ ,
                                                              @univ1 ,
                                                              NULL ,
                                                              NULL)
                                                        INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement ,
                                                              PlanID ,
                                                              dTaux_AvantDelaiRI ,
                                                              dTaux_ApresDelaiRI ,
                                                              dTaux_Individuel ,
                                                              dTaux_Individuel_RIO)
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              11 ,
                                                              @univ ,
                                                              @univ1 ,
                                                              NULL ,
                                                              NULL)
                                                        */

								--REEEFLEX
                                                        INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement,
                                                              PlanID,
                                                              dTaux_AvantDelaiRI,
                                                              dTaux_ApresDelaiRI,
                                                              dTaux_Individuel,
                                                              dTaux_Individuel_RIO)
                                                        SELECT 
                                                            @iID_TauxRendement,
                                                            P.PlanID,
                                                            @reeeflex,
                                                            @reeeflex1,
                                                            NULL,
                                                            NULL
                                                        FROM Un_Plan P
                                                        JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
                                                        WHERE RR.vcCode_Regroupement = 'REF'

                                                        /*
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              10 ,
                                                              @reeeflex ,
                                                              @reeeflex1 ,
                                                              NULL ,
                                                              NULL)

                                                        INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement ,
                                                              PlanID ,
                                                              dTaux_AvantDelaiRI ,
                                                              dTaux_ApresDelaiRI ,
                                                              dTaux_Individuel ,
                                                              dTaux_Individuel_RIO)
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              12 ,
                                                              @reeeflex ,
                                                              @reeeflex1 ,
                                                              NULL ,
                                                              NULL)

														INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement ,
                                                              PlanID ,
                                                              dTaux_AvantDelaiRI ,
                                                              dTaux_ApresDelaiRI ,
                                                              dTaux_Individuel ,
                                                              dTaux_Individuel_RIO)
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              13 ,
                                                              @reeeflex ,
                                                              @reeeflex1 ,
                                                              NULL ,
                                                              NULL)
                                                        */

								--INDIVIDUEL
                                                        INSERT INTO tblOPER_RendementTaux
                                                              (iID_Taux_Rendement,
                                                              PlanID,
                                                              dTaux_AvantDelaiRI,
                                                              dTaux_ApresDelaiRI,
                                                              dTaux_Individuel,
                                                              dTaux_Individuel_RIO)
                                                        SELECT 
                                                            @iID_TauxRendement,
                                                            P.PlanID,
                                                            NULL,
                                                            NULL,
                                                            @indiv,
                                                            @indiv1
                                                        FROM Un_Plan P
                                                        JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
                                                        WHERE RR.vcCode_Regroupement = 'IND'

                                                        /*
                                                        VALUES
                                                              (@iID_TauxRendement ,
                                                              4 ,
                                                              NULL ,
                                                              NULL ,
                                                              @indiv ,
                                                              @indiv1)
                                                        */
                                                    END
                                            END
                                    END
                                SET @i = @i + 1

                                FETCH MyCursor INTO @univ, @univ1, @reeeflex,
                                    @reeeflex1, @indiv, @indiv1,
                                    @typeRendement
                            END
                        CLOSE MyCursor
                        DEALLOCATE MyCursor

                        SET @cMessage = 'Vous avez importé les taux suivants : '

                        IF EXISTS ( 
									SELECT name
                                    FROM sysobjects
                                    WHERE name = 'tblTEMP_Importation' )
                            BEGIN
                                DROP TABLE tblTEMP_Importation
                            END

                        SELECT DISTINCT
                            temp.id AS id ,
                            temp.[Type de rendement] ,
                            temp.[no taux] ,
                            d.dTaux_AvantDelaiRI AS "universitas" ,
                            d.dTaux_ApresDelaiRI AS "universitas1" ,
                            b.dTaux_AvantDelaiRI AS "reeeflex" ,
                            b.dTaux_ApresDelaiRI AS "reeeflex1" ,
                            c.dTaux_Individuel AS "individuelAvant_RI" ,
                            c.dTaux_Individuel_RIO AS "individuelApres_RI" ,
                            @dateOPER AS "date_operation" ,
                            @cMessage AS "message"
                        INTO
                            #tmpTempo
                        FROM tblOPER_RendementTaux a
                        LEFT JOIN (
								SELECT DISTINCT
                                    iID_Taux_Rendement ,
                                    dTaux_AvantDelaiRI ,
                                    dTaux_ApresDelaiRI
                                FROM tblOPER_RendementTaux
								WHERE PlanID = 10
								) AS b ON a.iID_Taux_Rendement = b.iID_Taux_Rendement
                        LEFT JOIN (
                                SELECT DISTINCT
									iID_Taux_Rendement ,
									dTaux_Individuel ,
									dTaux_Individuel_RIO
                                FROM tblOPER_RendementTaux
                                WHERE PlanID = 4
                                  ) AS c ON a.iID_Taux_Rendement = c.iID_Taux_Rendement
                        LEFT JOIN (
								SELECT DISTINCT
                                    iID_Taux_Rendement ,
                                    dTaux_AvantDelaiRI ,
                                    dTaux_ApresDelaiRI
                                FROM tblOPER_RendementTaux
								WHERE PlanID = 8
								) AS d ON a.iID_Taux_Rendement = d.iID_Taux_Rendement
                        JOIN tblOPER_TauxRendement tr ON a.iID_Taux_Rendement = tr.iID_Taux_Rendement
                        JOIN tblOPER_Rendements r ON tr.iID_Rendement = r.iID_Rendement
                        JOIN tmpRendement temp ON temp.idTypeRendement = r.tiID_Type_Rendement
                        WHERE tr.dtDate_Operation = @dateOPER
                        ORDER BY temp.id

                        SELECT
                            *
                        FROM #tmpTempo
                        UNION ALL
                        SELECT
                            NULL ,
                            NULL ,
                            NULL ,
                            NULL ,
                            NULL ,
                            NULL ,
                            NULL ,
                            NULL ,
                            NULL ,
                            @dateOPER ,
                            'aucun taux importé'
                        WHERE NOT EXISTS ( 
										SELECT
                                            *
                                         FROM #tmpTempo )

                    END
                ELSE
                    BEGIN
                        SELECT
                            r.id ,
                            r.[Type de rendement] ,
                            r.[No taux] ,
                            r.UNIVERSITAS ,
                            r.UNIVERSITAS1 ,
                            r.REEEFLEX ,
                            r.REEEFLEX1 ,
                            r.individuelAvant_RI ,
                            r.individuelApres_RI ,
                            @dateOPER AS date_operation ,
                            @cMessage AS message
                        FROM tmpRendement r
                        WHERE [Type de rendement] IS NOT NULL
                        ORDER BY r.id
                    END


                IF EXISTS ( 
							SELECT name
                            FROM sysobjects
                            WHERE name = 'tmpRendement' )
                    BEGIN
                        DROP TABLE tmpRendement
                    END
            END 

    END TRY
    BEGIN CATCH
        DECLARE
            @iErrSeverite INT ,
            @iErrStatut INT ,
            @vcErrMsg NVARCHAR(1024)

        SELECT
            @vcErrMsg = REPLACE(ERROR_MESSAGE(), '%', ' ') ,
            @iErrStatut = ERROR_STATE() ,
            @iErrSeverite = ERROR_SEVERITY()

        RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
    END CATCH
END